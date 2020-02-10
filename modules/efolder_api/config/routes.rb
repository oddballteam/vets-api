# frozen_string_literal: true

EfolderApi::Engine.routes.draw do
  match '/v0/*path', to: 'application#cors_preflight', via: [:options]
  namespace :v0, defaults: { format: 'json'} do
    resources :documents
  end
  
  # namespace :v0, defaults: { format: 'json' } do
  #   resources :upload, only: %i[create show]
  # end
end
