# frozen_string_literal: true
module Common
  module Exceptions
    # Service Outage - Breakers is reporting an outage on a backend system
    class ServiceOutage < BaseError
      def initialize(outage = nil, options = {})
        @outage = outage
        @detail = options[:detail]
      end

      def errors
        detail = @detail || "An outage has been reported on the #{@outage.service.name} since #{@outage.start_time}"
        Array(SerializableError.new(MinorCodes::SERVICE_OUTAGE.merge(detail: detail)))
      end
    end
  end
end
