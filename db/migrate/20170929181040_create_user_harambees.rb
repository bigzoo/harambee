class CreateUserHarambees < ActiveRecord::Migration[5.1]
  def change
    create_table :user_harambees do |t|
      t.string :name
      t.integer :user_id
      t.string :description
      t.string :target_amount
      t.string :raised_amount
      t.string :phone_no
      t.datetime :deadline
      t.boolean :running, default: true

      t.timestamps
    end
    add_index :user_harambees, :user_id
  end
end
