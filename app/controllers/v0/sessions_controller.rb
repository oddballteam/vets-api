# frozen_string_literal: true
module V0
  class SessionsController < ApplicationController
    skip_before_action :authenticate, only: [:new, :saml_callback, :saml_logout_callback]

    def new
      saml_auth_request = OneLogin::RubySaml::Authrequest.new
      render json: { authenticate_via_get: saml_auth_request.create(saml_settings) }
    end

    def destroy
      logout_request = OneLogin::RubySaml::Logoutrequest.new
      logger.info "New SP SLO for userid '#{@session.uuid}'"

      render json: { logout_via_get: logout_request.create(saml_settings, RelayState: @session.token) }, status: 202
    end

    def saml_logout_callback
      if params[:SAMLResponse]
        # We initiated an SLO and are receiving the bounce-back after the IDP performed it
        handle_completed_slo
      end
    end

    def saml_callback
      @saml_response = OneLogin::RubySaml::Response.new(
        params[:SAMLResponse], settings: saml_settings
      )

      if @saml_response.is_valid? && persist_session_and_user
        async_create_evss_account(@current_user)
        redirect_to SAML_CONFIG['relay'] + '?token=' + @session.token
      else
        logger.warn 'Authentication attempt did not succeed in saml_callback, reasons...'
        logger.warn "  SAML Response: valid?=#{@saml_response.is_valid?} errors=#{@saml_response.errors}"
        logger.warn "  User: valid?=#{@current_user&.valid?} errors=#{@current_user&.errors&.messages}"
        logger.warn "  Session: valid?=#{@session&.valid?} errors=#{@session&.errors&.messages}"
        redirect_to SAML_CONFIG['relay'] + '?auth=fail'
      end
    end

    private

    def persist_session_and_user
      @session = Session.new(user_attributes.slice(:uuid))
      @current_user = User.find(@session.uuid)
      @current_user = @current_user.nil? ? saml_user : User.from_merged_attrs(@current_user, saml_user)
      @session.save && @current_user.save
    end

    def user_attributes
      attributes = @saml_response.attributes.all.to_h
      {
        first_name:     attributes['fname']&.first,
        middle_name:    attributes['mname']&.first,
        last_name:      attributes['lname']&.first,
        zip:            attributes['zip']&.first,
        email:          attributes['email']&.first,
        gender:         parse_gender(attributes['gender']&.first),
        ssn:            attributes['social']&.first&.delete('-'),
        birth_date:     attributes['birth_date']&.first,
        uuid:           attributes['uuid']&.first,
        last_signed_in: Time.current.utc,
        loa:            { current: loa_current, highest: loa_highest(attributes) }
      }
    end

    def parse_gender(gender)
      return nil unless gender
      gender[0].upcase
    end

    def loa_current
      @raw_loa ||= REXML::XPath.first(@saml_response.decrypted_document, '//saml:AuthnContextClassRef')&.text
      LOA::MAPPING[@raw_loa]
    end

    def loa_highest(attributes)
      logger.warn 'LOA.highest is nil!' if (loa = attributes['level_of_assurance']&.first&.to_i).nil?
      loa_highest = loa || loa_current
      logger.warn 'LOA.highest is less than LOA.current' if loa_highest < loa_current
      [loa_current, loa_highest].max
    end

    def saml_user
      @saml_user ||= User.new(user_attributes)
    end

    def async_create_evss_account(user)
      return unless user.can_access_evss?
      auth_headers = EVSS::AuthHeaders.new(user).to_h
      EVSS::CreateUserAccountJob.perform_async(auth_headers)
    end

    # :nocov:
    def handle_completed_slo
      logout_response = OneLogin::RubySaml::Logoutresponse.new(params[:SAMLResponse], saml_settings)

      logger.info "LogoutResponse is: #{logout_response}"

      if !logout_response.validate(true)
        logger.error 'The SAML Logout Response is invalid'
        logger.error "ERROR MESSAGES #{logout_response.errors.join(' ---- ')}"
        redirect_to SAML_CONFIG['logout_relay'] + '?success=false'
      elsif logout_response.success?
        begin
          session = Session.find(params[:RelayState])
          user = User.find(session.uuid)
          MHVLoggingService.logout(user)
        rescue => e
          logger.error "Error in MHV Logout: #{e.message}"
        end
        delete_session(params[:RelayState])
        redirect_to SAML_CONFIG['logout_relay'] + '?success=true'
      end
    end

    def delete_session(token)
      session = Session.find(token)
      unless session.nil?
        User.find(session.uuid)&.destroy
        session.destroy
      end
    end
    # :nocov:
  end
end
