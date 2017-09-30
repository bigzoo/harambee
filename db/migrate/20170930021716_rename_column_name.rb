class RenameColumnName < ActiveRecord::Migration[5.1]
  def change
    rename_column :transactions, :harambee_id, :user_harambee_id
  end
end
