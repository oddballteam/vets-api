# frozen_string_literal: true

require_dependency 'vaos/application_controller'

module VAOS
  class SystemsController < ApplicationController
    def index
      response = systems_service.get_systems(current_user)
      render json: VAOS::SystemSerializer.new(response)
    end

    private

    def systems_service
      VAOS::SystemsService.new
    end
  end
end