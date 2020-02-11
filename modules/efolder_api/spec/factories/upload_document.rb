# frozen_string_literal: true

FactoryBot.define do
    factory :upload_document, class: 'EfolderApi::Document' do
      guid { 'f7027a14-6abd-4087-b397-3d84d445f4c3' }
      status { 'pending' }
  
      trait :status_received do
        status { 'received' }
      end
  
      trait :status_uploaded do
        status { 'uploaded' }
      end
  
      trait :status_error do
        status { 'error' }
        detail { 'Upload rejected' }
      end
    end
  end
  