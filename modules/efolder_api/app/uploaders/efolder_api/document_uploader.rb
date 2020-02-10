# frozen_string_literal: true
# encoding: utf-8

module EfolderApi
  class DocumentUploader < ::CarrierWave::Uploader::Base
    include ValidateFileSize
    include SetAwsConfig
    include UploaderVirusScan
    
    MAX_FILE_SIZE = 50.megabytes
    def initialize(file, *args)
      super
      @guid = file.guid

      if Rails.env.production?
        set_aws_config(
          # TODO: configure settings
          Settings.efolder_api.s3.aws_access_key_id,
          Settings.efolder_api.s3.aws_secret_access_key,
          Settings.efolder_api.s3.region,
          Settings.efolder_api.s3.bucket
        )
      end
    end
  
    def store_dir
      raise 'missing guid' if @guid.blank?
      "efolder_documents/#{@guid}"
    end
  
    # TODO: determine valid types
    def extension_white_list
      %w[pdf jpg jpeg png]
    end

    def filename
      super.chomp(File.extname(super)) + '.pdf' if original_filename.present?
    end
  
  
  end
  
end
