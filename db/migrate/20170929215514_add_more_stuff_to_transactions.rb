class AddMoreStuffToTransactions < ActiveRecord::Migration[5.1]
  def change
    add_column :transactions, :receipt_no, :string
    add_column :transactions, :transaction_date, :string
  end
end
