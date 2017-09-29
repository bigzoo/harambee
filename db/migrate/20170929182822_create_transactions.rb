class CreateTransactions < ActiveRecord::Migration[5.1]
  def change
    create_table :transactions do |t|
      t.integer :harambee_id
      t.string :contributor_amount
      t.string :contributor_phone_no
      t.string :transaction_code
      t.string :transaction_confirmation

      t.timestamps
    end
    add_index :transactions, :harambee_id
  end
end
