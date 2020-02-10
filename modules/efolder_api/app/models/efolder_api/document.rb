# frozen_string_literal: true

module EfolderApi
  class Document < ApplicationRecord
    include SetGuid
    mount_uploader :file, DocumentUploader
  end
end
