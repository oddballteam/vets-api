# frozen_string_literal: true

require_dependency "efolder_api/application_controller"

module EfolderApi
  module V0
    class DocumentsController < ApplicationController
      skip_before_action(:authenticate)
      before_action :set_document, only: [:show, :update, :destroy]
  
      # GET /documents
      # TODO: delete this
      def index
        @documents = Document.all
  
        render json: @documents
      end
  
      # GET /documents/<guid>
      def show
        render json: @document
      end
  
      # POST /documents
      def create
        @document = Document.new
  
        if @document.save
          render json: @document.guid, status: :ok
          # render json: @document, status: :created, location: @document
        else
          render json: @document.errors, status: :unprocessable_entity
        end
      end
  
      # PATCH/PUT /documents/1
      def update
        if @document.update(document_params)
          render json: @document
        else
          render json: @document.errors, status: :unprocessable_entity
        end
      end
  
      # DELETE /documents/1
      def destroy
        @document.destroy
      end
  
      private
        def set_document
          @document = Document.find_by_guid(params[:guid])
          @document
        end
  
        # Only allow a trusted parameter "white list" through.
        def document_params
          params.require(:document).permit(:name, :content_hash, :guid, :status, :file)
        end
    end
  end
end
