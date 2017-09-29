class AddDefaultValueToUserHarambeesRaisedAmount < ActiveRecord::Migration[5.1]
  def change
    change_column :user_harambees, :raised_amount, :string, :default => 0
  end
end
