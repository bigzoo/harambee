class AddDoneToTransactions < ActiveRecord::Migration[5.1]
  def change
    add_column :transactions, :done, :boolean
  end
end
