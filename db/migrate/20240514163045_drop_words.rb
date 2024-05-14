class DropWords < ActiveRecord::Migration[7.0]
  def change
    drop_table :words
  end
end
