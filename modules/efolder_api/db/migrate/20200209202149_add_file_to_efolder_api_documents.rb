class AddFileToEfolderApiDocuments < ActiveRecord::Migration[5.2]
  def change
    add_column :efolder_api_documents, :file, :string
  end
end
