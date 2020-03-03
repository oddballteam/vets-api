# frozen_string_literal: true

module StructuredData
  class ProcessDataJob
    include Sidekiq::Worker

    sidekiq_options retry: false

    class StructuredDataResponseError < StandardError
    end
    def perform(saved_claim_id)
      begin
        stats_key = BipClaims::Service::STATSD_KEY_PREFIX

        PensionBurial::TagSentry.tag_sentry

        @claim = SavedClaim.find(saved_claim_id)

        veteran = BipClaims::Service.new.lookup_veteran_from_mvi(@claim)

        claimant = lookup_claimant(veteran, @claim) if veteran
      ensure
        @claim.process_attachments! # upload claim and attachments to Central Mail

        # veteran lookup for hit/miss metrics in support of Automation work
        StatsD.increment("#{stats_key}.success", tags: [
                           "relationship:#{relationship_type}",
                           "veteranInMVI:#{veteran&.participant_id.present?}",
                           "claimantFound:#{claimant.present?}"
                         ])
      end
    rescue
      raise
    end

    def lookup_claimant(veteran, claim)
      relationship_type = claim.parsed_form['relationship']&.fetch('type', nil)
      claimant_name = claim.parsed_form['claimantFullName']
      claimant_address = claim.parsed_form['claimantAddress']

      case relationship_type
      when 'child'
        StructuredData::Utilities.find_dependent_claimant(veteran, claimant_name, claimant_address)
      end
    end
  end
end
