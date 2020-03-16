# frozen_string_literal: true

require 'base64'
require 'saml/url_service'
require 'saml/responses/login'
require 'saml/responses/logout'

module V1
  class SessionsController < ApplicationController
    skip_before_action :validate_csrf_token!

    REDIRECT_URLS = %w[signup mhv dslogon idme mfa verify slo ssoe_slo].freeze

    STATSD_SSO_NEW_KEY = 'api.auth.new'
    STATSD_SSO_CALLBACK_KEY = 'api.auth.saml_callback'
    STATSD_SSO_CALLBACK_TOTAL_KEY = 'api.auth.login_callback.total'
    STATSD_SSO_CALLBACK_FAILED_KEY = 'api.auth.login_callback.failed'
    STATSD_LOGIN_NEW_USER_KEY = 'api.auth.new_user'
    STATSD_LOGIN_STATUS = 'api.auth.login'
    STATSD_LOGIN_SHARED_COOKIE = 'api.auth.sso_shared_cookie'

    # Collection Action: auth is required for certain types of requests
    # @type is set automatically by the routes in config/routes.rb
    # For more details see SAML::SettingsService and SAML::URLService
    def new
      type = params[:type]
      raise Common::Exceptions::RoutingError, params[:path] unless REDIRECT_URLS.include?(type)

      StatsD.increment(STATSD_SSO_NEW_KEY,
                       tags: ["context:#{type}", "forceauthn:#{force_authn?}"])
      url = url_service.send("#{type}_url")

      if %w[slo ssoe_slo].include?(type)
        Rails.logger.info("LOGOUT of type #{type}", sso_logging_info)
        reset_session
      end
      # clientId must be added at the end or the URL will be invalid for users using various "Do not track"
      # extensions with their browser.
      redirect_to params[:client_id].present? ? url + "&clientId=#{params[:client_id]}" : url
    end

    def ssoe_slo_callback
      redirect_to url_service.logout_redirect_url
    end

    def saml_logout_callback
      saml_response = SAML::Responses::Logout.new(params[:SAMLResponse], saml_settings, raw_get_params: params)
      Raven.extra_context(in_response_to: saml_response.try(:in_response_to) || 'ERROR')

      if saml_response.valid?
        user_logout(saml_response)
      else
        log_error(saml_response)
        Rails.logger.info("SLO callback response invalid for originating_request_id '#{originating_request_id}'")
      end
    rescue => e
      log_exception_to_sentry(e, {}, {}, :error)
    ensure
      redirect_to url_service.logout_redirect_url
    end

    def saml_callback
      saml_response = SAML::Responses::Login.new(params[:SAMLResponse], settings: saml_settings)
      if saml_response.valid?
        user_login(saml_response)
      else
        log_error(saml_response)
        redirect_to url_service.login_redirect_url(auth: 'fail', code: auth_error_code(saml_response.error_code))
        callback_stats(:failure, saml_response, saml_response.error_instrumentation_code)
      end
    rescue => e
      log_exception_to_sentry(e, {}, {}, :error)
      redirect_to url_service.login_redirect_url(auth: 'fail', code: '007') unless performed?
      callback_stats(:failed_unknown)
    ensure
      callback_stats(:total)
    end

    def metadata
      meta = OneLogin::RubySaml::Metadata.new
      render xml: meta.generate(saml_settings), content_type: 'application/xml'
    end

    private

    def force_authn?
      params[:force]&.downcase == 'true'
    end

    def saml_settings(options = {})
      # add a forceAuthn value to the saml settings based on the initial options or
      # the "force" value in the query params
      options[:force_authn] ||= force_authn?
      SAML::SSOeSettingsService.saml_settings(options)
    end

    def auth_error_code(code)
      if code == '005' && validate_session
        UserSessionForm::ERRORS[:saml_replay_valid_session][:code]
      else
        code
      end
    end

    def authenticate
      return unless action_name == 'new'

      if %w[mfa verify slo].include?(params[:type])
        super
      else
        reset_session
      end
    end

    def log_error(saml_response)
      log_message_to_sentry(saml_response.errors_message,
                            saml_response.errors_hash[:level],
                            saml_error_context: saml_response.errors_context)
    end

    def user_login(saml_response)
      user_session_form = UserSessionForm.new(saml_response)
      if user_session_form.valid?
        @current_user, @session_object = user_session_form.persist
        set_cookies
        after_login_actions
        redirect_to url_service.login_redirect_url
        if location.start_with?(url_service.base_redirect_url)
          # only record success stats if the user is being redirect to the site
          # some users will need to be up-leveled and this will be redirected
          # back to the identity provider
          login_stats(:success, saml_response)
        end
      else
        log_message_to_sentry(
          user_session_form.errors_message, user_session_form.errors_hash[:level], user_session_form.errors_context
        )
        redirect_to url_service.login_redirect_url(auth: 'fail', code: user_session_form.error_code)
        login_stats(:failure, saml_response, user_session_form)
      end
    end

    def user_logout(saml_response)
      logout_request = SingleLogoutRequest.find(saml_response&.in_response_to)
      if logout_request.present?
        logout_request.destroy
        Rails.logger.info("SLO callback response to '#{saml_response&.in_response_to}' for originating_request_id "\
          "'#{originating_request_id}'")
      else
        Rails.logger.info('SLO callback response could not resolve logout request for originating_request_id '\
          "'#{originating_request_id}'")
      end
    end

    def login_stats(status, saml_response, user_session_form = nil)
      case status
      when :success
        StatsD.increment(STATSD_LOGIN_NEW_USER_KEY) if request_type == 'signup'
        # track users who have a shared sso cookie
        StatsD.increment(STATSD_LOGIN_SHARED_COOKIE,
                         tags: ["loa:#{@current_user.loa[:current]}",
                                "idp:#{@current_user.identity.sign_in[:service_name]}"])
        StatsD.increment(STATSD_LOGIN_STATUS,
                         tags: ['status:success',
                                "idp:#{@current_user.identity.sign_in[:service_name]}",
                                "context:#{saml_response.authn_context}"])
        callback_stats(:success, saml_response)
      when :failure
        StatsD.increment(STATSD_LOGIN_STATUS,
                         tags: ['status:failure',
                                "idp:#{params[:type]}",
                                "context:#{saml_response.authn_context}",
                                "error:#{user_session_form.error_instrumentation_code}"])
        callback_stats(:failure, saml_response, user_session_form.error_instrumentation_code)
      end
    end

    def callback_stats(status, saml_response = nil, failure_tag = nil)
      case status
      when :success
        StatsD.increment(STATSD_SSO_CALLBACK_KEY,
                         tags: ['status:success', "context:#{saml_response.authn_context}"])
        # track users who have a shared sso cookie
      when :failure
        StatsD.increment(STATSD_SSO_CALLBACK_KEY,
                         tags: ['status:failure', "context:#{saml_response.authn_context}"])
        StatsD.increment(STATSD_SSO_CALLBACK_FAILED_KEY, tags: [failure_tag])
      when :failed_unknown
        StatsD.increment(STATSD_SSO_CALLBACK_KEY,
                         tags: ['status:failure', 'context:unknown'])
        StatsD.increment(STATSD_SSO_CALLBACK_FAILED_KEY, tags: ['error:unknown'])
      when :total
        StatsD.increment(STATSD_SSO_CALLBACK_TOTAL_KEY)
      end
    end

    def set_cookies
      Rails.logger.info('SSO: LOGIN', sso_logging_info)
      set_api_cookie!
      set_sso_cookie!
    end

    def after_login_actions
      AfterLoginJob.perform_async('user_uuid' => @current_user&.uuid)
      log_persisted_session_and_warnings
    end

    def log_persisted_session_and_warnings
      obscure_token = Session.obscure_token(@session_object.token)
      Rails.logger.info("Logged in user with id #{@session_object.uuid}, token #{obscure_token}")
      # We want to log when SSNs do not match between MVI and SAML Identity. And might take future
      # action if this appears to be happening frquently.
      if current_user.ssn_mismatch?
        additional_context = StringHelpers.heuristics(current_user.identity.ssn, current_user.va_profile.ssn)
        log_message_to_sentry('SSNS DO NOT MATCH!!', :warn, identity_compared_with_mvi: additional_context)
      end
    end

    def originating_request_id
      JSON.parse(params[:RelayState] || '{}')['originating_request_id']
    rescue
      'UNKNOWN'
    end

    def request_type
      JSON.parse(params[:RelayState] || '{}')['type']
    rescue
      'UNKNOWN'
    end

    def url_service
      SAML::URLService.new(saml_settings, session: @session_object, user: current_user,
                                          params: params, loa3_context: LOA::IDME_LOA3)
    end
  end
end
