# frozen_string_literal: true

require_dependency 'vaos/application_controller'

module VAOS
  class VisitsController < ApplicationController
    def direct
      response = systems_service.get_facility_clinics(
        current_user,
        visits_params[:facility_id],
        visits_params[:type_of_care_id],
        visits_params[:system_id]
      )
      render json: VAOS::VisitSerializer.new(response)
    end

    def request
      response = systems_service.get_facility_clinics(
        current_user,
        visits_params[:facility_id],
        visits_params[:type_of_care_id],
        visits_params[:system_id]
      )
      render json: VAOS::VisitSerializer.new(response)
    end

    private

    def systems_service
      VAOS::SystemsService.new
    end

    def visits_params
      params.require(:facility_id)
      params.require(:type_of_care_id)
      params.require(:system_id)
      params.permit(
        :facility_id,
        :type_of_care_id,
        :system_id
      )
    end
  end
end
