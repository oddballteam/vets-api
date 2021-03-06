# frozen_string_literal: true

require 'rails_helper'

describe VAOS::SystemsService do
  subject { VAOS::SystemsService.new(user) }

  let(:user) { build(:user, :mhv) }

  before { allow_any_instance_of(VAOS::UserService).to receive(:session).and_return('stubbed_token') }

  describe '#get_systems' do
    context 'with 10 identifiers and 4 systems' do
      it 'returns an array of size 4' do
        VCR.use_cassette('vaos/systems/get_systems', match_requests_on: %i[method uri]) do
          response = subject.get_systems
          expect(response.size).to eq(4)
        end
      end

      it 'increments metrics total' do
        VCR.use_cassette('vaos/systems/get_systems', match_requests_on: %i[method uri]) do
          expect { subject.get_systems }.to trigger_statsd_increment(
            'api.vaos.get_systems.total', times: 1, value: 1
          )
        end
      end
    end

    context 'when the upstream server returns a 500' do
      it 'raises a backend exception' do
        VCR.use_cassette('vaos/systems/get_systems_500', match_requests_on: %i[method uri]) do
          expect { subject.get_systems }.to trigger_statsd_increment(
            'api.vaos.get_systems.total', times: 1, value: 1
          ).and trigger_statsd_increment(
            'api.vaos.get_systems.fail', times: 1, value: 1
          ).and raise_error(Common::Exceptions::BackendServiceException)
        end
      end
    end

    context 'when the upstream server returns a 403' do
      it 'raises a backend exception' do
        VCR.use_cassette('vaos/systems/get_systems_403', match_requests_on: %i[method uri]) do
          expect { subject.get_systems }.to trigger_statsd_increment(
            'api.vaos.get_systems.fail', times: 1, value: 1
          ).and raise_error(Common::Exceptions::BackendServiceException)
        end
      end
    end
  end

  describe '#get_facilities' do
    context 'with 141 facilities' do
      it 'returns an array of size 141' do
        VCR.use_cassette('vaos/systems/get_facilities', match_requests_on: %i[method uri]) do
          response = subject.get_facilities('688')
          expect(response.size).to eq(141)
        end
      end
    end

    context 'when the upstream server returns a 500' do
      it 'raises a backend exception' do
        VCR.use_cassette('vaos/systems/get_facilities_500', match_requests_on: %i[method uri]) do
          expect { subject.get_facilities('688') }.to raise_error(
            Common::Exceptions::BackendServiceException
          )
        end
      end
    end
  end

  describe '#get_facility_clinics' do
    context 'with 1 clinic' do
      it 'returns an array of size 1' do
        VCR.use_cassette('vaos/systems/get_facility_clinics', match_requests_on: %i[method uri]) do
          response = subject.get_facility_clinics('983', '323', '983')
          expect(response.size).to eq(4)
        end
      end
    end

    context 'when the upstream server returns a 500' do
      it 'raises a backend exception' do
        VCR.use_cassette('vaos/systems/get_facility_clinics_500', match_requests_on: %i[method uri]) do
          expect { subject.get_facility_clinics('984GA', '323', '984') }.to raise_error(
            Common::Exceptions::BackendServiceException
          )
        end
      end
    end
  end

  describe '#get_cancel_reasons' do
    context 'with a 200 response' do
      it 'returns an array of size 6' do
        VCR.use_cassette('vaos/systems/get_cancel_reasons', match_requests_on: %i[method uri]) do
          response = subject.get_cancel_reasons('984')
          expect(response.size).to eq(6)
        end
      end
    end

    context 'when the upstream server returns a 500' do
      it 'raises a backend exception' do
        VCR.use_cassette('vaos/systems/get_cancel_reasons_500', match_requests_on: %i[method uri]) do
          expect { subject.get_cancel_reasons('984') }.to raise_error(
            Common::Exceptions::BackendServiceException
          )
        end
      end
    end
  end

  describe '#get_available_appointments' do
    let(:facility_id) { '688' }
    let(:start_date) { DateTime.new(2019, 11, 22) }
    let(:end_date) { DateTime.new(2020, 2, 19) }
    let(:clinic_ids) { ['2276'] }

    context 'with a 200 response' do
      it 'lists available times by facility with coerced dates' do
        VCR.use_cassette('vaos/systems/get_facility_available_appointments', match_requests_on: %i[method uri]) do
          response = subject.get_facility_available_appointments(facility_id, start_date, end_date, clinic_ids)
          clinic = response.first
          first_available_time = clinic.appointment_time_slot.first
          expect(clinic.clinic_id).to eq(clinic_ids.first)
          expect(first_available_time.start_date_time.to_s).to eq('2019-12-02T13:30:00+00:00')
        end
      end
    end

    context 'when the upstream server returns a 500' do
      it 'raises a backend exception' do
        VCR.use_cassette('vaos/systems/get_facility_appointments', match_requests_on: %i[method uri]) do
          expect { subject.get_cancel_reasons('984') }.to raise_error(
            Common::Exceptions::BackendServiceException
          )
        end
      end
    end
  end

  describe '#get_system_facilities' do
    context 'with a 200 response' do
      it 'returns the six facilities for the system with id of 688' do
        VCR.use_cassette('vaos/systems/get_system_facilities', match_requests_on: %i[method uri]) do
          response = subject.get_system_facilities('688', '688', '323')
          expect(response.size).to eq(6)
        end
      end

      it 'flattens the facility data' do
        VCR.use_cassette('vaos/systems/get_system_facilities', match_requests_on: %i[method uri]) do
          response = subject.get_system_facilities('688', '688', '323')
          facility = response.first.to_h
          expect(facility).to eq(
            request_supported: true,
            direct_scheduling_supported: true,
            express_times: nil,
            institution_timezone: 'America/New_York',
            institution_code: '688',
            name: 'Washington VA Medical Center',
            city: 'Washington',
            state_abbrev: 'DC',
            authoritative_name: 'Washington VA Medical Center',
            root_station_code: '688',
            admin_parent: true, parent_station_code: '688'
          )
        end
      end
    end

    context 'when the upstream server returns a 500' do
      it 'raises a backend exception' do
        VCR.use_cassette('vaos/systems/get_system_facilities_500', match_requests_on: %i[method uri]) do
          expect { subject.get_system_facilities('688', '688', '323') }.to raise_error(
            Common::Exceptions::BackendServiceException
          )
        end
      end
    end
  end

  describe '#get_facility_limits' do
    context 'with a 200 response' do
      it 'returns the number of requests and limits for a facility' do
        VCR.use_cassette('vaos/systems/get_facility_limits', match_requests_on: %i[method uri]) do
          response = subject.get_facility_limits('688', '323')
          expect(response.number_of_requests).to eq(0)
          expect(response.request_limit).to eq(1)
        end
      end
    end

    context 'when the upstream server returns a 500' do
      it 'raises a backend exception' do
        VCR.use_cassette('vaos/systems/get_facility_limits_500', match_requests_on: %i[method uri]) do
          expect { subject.get_facility_limits('688', '323') }.to raise_error(
            Common::Exceptions::BackendServiceException
          )
        end
      end
    end
  end

  describe '#get_system_pact' do
    context 'with a 200 response' do
      it 'returns pact info' do
        VCR.use_cassette('vaos/systems/get_system_pact', match_requests_on: %i[method uri]) do
          response = subject.get_system_pact('688')
          expect(response.size).to eq(6)
          expect(response.first.to_h).to eq(
            facility_id: '688',
            possible_primary: 'Y',
            provider_position: 'GREEN-FOUR PHYSICIAN',
            provider_sid: '3780868',
            staff_name: 'VASSALL,NATALIE M',
            team_name: 'GREEN-FOUR',
            team_purpose: 'PRIMARY CARE',
            team_sid: '1400018881',
            title: 'PHYSICIAN-ATTENDING'
          )
        end
      end
    end

    context 'when the upstream server returns a 500' do
      it 'raises a backend exception' do
        VCR.use_cassette('vaos/systems/get_system_pact_500', match_requests_on: %i[method uri]) do
          expect { subject.get_system_pact('688') }.to raise_error(
            Common::Exceptions::BackendServiceException
          )
        end
      end
    end
  end

  describe '#get_facility_visits' do
    context 'with a 200 response for direct visits that is false' do
      it 'returns facility information showing no visits' do
        VCR.use_cassette('vaos/systems/get_facility_visits', match_requests_on: %i[method uri]) do
          response = subject.get_facility_visits('688', '688', '323', 'direct')
          expect(response.has_visited_in_past_months).to be_falsey
          expect(response.duration_in_months).to eq(0)
        end
      end
    end

    context 'with a 200 response for request visits that is true' do
      it 'returns facility information showing a past visit' do
        VCR.use_cassette('vaos/systems/get_facility_visits_request', match_requests_on: %i[method uri]) do
          response = subject.get_facility_visits('688', '688', '323', 'request')
          expect(response.has_visited_in_past_months).to be_truthy
          expect(response.duration_in_months).to eq(2)
        end
      end
    end

    context 'when the upstream server returns a 500' do
      it 'raises a backend exception' do
        VCR.use_cassette('vaos/systems/get_system_pact_500', match_requests_on: %i[method uri]) do
          expect { subject.get_system_pact('688') }.to raise_error(
            Common::Exceptions::BackendServiceException
          )
        end
      end
    end

    context 'when the upstream server returns a 500' do
      it 'raises a backend exception' do
        VCR.use_cassette('vaos/systems/get_facility_visits_500', match_requests_on: %i[method uri]) do
          expect { subject.get_facility_visits('688', '688', '323', 'direct') }.to raise_error(
            Common::Exceptions::BackendServiceException
          )
        end
      end
    end
  end

  describe '#get_clinic_institutions' do
    context 'with a 200 response for a set of clinic ids' do
      let(:system_id) { 442 }
      let(:clinic_ids) { [16, 90, 110, 192, 193] }

      it 'returns only those clinics parsed correctly', :aggregate_failures do
        VCR.use_cassette('vaos/systems/get_institutions', match_requests_on: %i[method uri]) do
          response = subject.get_clinic_institutions(system_id, clinic_ids)
          expect(response.map { |c| c[:location_ien].to_i }).to eq(clinic_ids)
          expect(response.last.to_h).to eq(
            institution_code: '442',
            institution_ien: '442',
            institution_name: 'CHEYENNE VA MEDICAL',
            institution_sid: 561_596,
            location_ien: '193'
          )
        end
      end
    end

    context 'with a 200 response for a set of clinic ids' do
      let(:system_id) { 442 }
      let(:clinic_ids) { 16 }

      it 'returns only those clinics parsed correctly', :aggregate_failures do
        VCR.use_cassette('vaos/systems/get_institutions_single', match_requests_on: %i[method uri]) do
          response = subject.get_clinic_institutions(system_id, clinic_ids)
          expect(response.map { |c| c[:location_ien].to_i }).to eq([*clinic_ids])
          expect(response.first.to_h).to eq(
            institution_code: '442',
            institution_ien: '442',
            institution_name: 'CHEYENNE VA MEDICAL',
            institution_sid: 561_596,
            location_ien: '16'
          )
        end
      end
    end
  end
end
