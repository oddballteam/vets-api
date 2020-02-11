# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'eFolder API document endpoint', type: :request do
  describe '#get /v0/documents' do
    it 'returns JSON' do
      get '/services/efolder/v0/documents'
      expect(response).to have_http_status(:ok)
      JSON.parse(response.body)
    end
  end
end
  