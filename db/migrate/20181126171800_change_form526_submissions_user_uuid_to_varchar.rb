class ChangeForm526SubmissionsUserUuidToVarchar < ActiveRecord::Migration
  def change
    change_column :form526_submissions, :user_uuid, :string, null: false
  end
end
