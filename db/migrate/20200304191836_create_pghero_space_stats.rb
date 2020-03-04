class CreatePgheroSpaceStats < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  def change
   add_index :pghero_query_stats, [:database, :captured_at], algorithm: :concurrently
   add_index :pghero_space_stats, [:database, :captured_at], algorithm: :concurrently
  end
end
