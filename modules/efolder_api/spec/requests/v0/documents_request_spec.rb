# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'services/efolder_api', type: :request do
  describe '#get /v0/documents' do
    it 'returns http status ok' do
      get '/services/efolder_api/v0/documents'
      expect(response).to have_http_status(:ok)
    end
  end
end
