class AddIdsTransaction < ActiveRecord::Migration[5.1]
  def change
    add_column :transactions, :merchant_request_id, :string
    add_column :transactions, :checkout_request_id, :string
  end
end
