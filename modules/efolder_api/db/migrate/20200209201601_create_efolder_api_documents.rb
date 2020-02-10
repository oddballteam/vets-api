class CreateEfolderApiDocuments < ActiveRecord::Migration[5.2]
  def change
    create_table :efolder_api_documents do |t|
      t.string :name
      t.string :content_hash
      t.string :guid
      t.string :status

      t.timestamps
    end
  end
end
