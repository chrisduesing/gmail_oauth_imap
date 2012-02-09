class AddInboxSizeToUser < ActiveRecord::Migration
  def change
    add_column :users, :inbox_size, :integer
  end
end
