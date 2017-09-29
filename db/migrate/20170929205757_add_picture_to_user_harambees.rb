class AddPictureToUserHarambees < ActiveRecord::Migration[5.1]
  def change
    add_column :user_harambees, :image, :string
  end
end
