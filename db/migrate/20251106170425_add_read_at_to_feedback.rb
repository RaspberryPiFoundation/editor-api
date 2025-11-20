class AddReadAtToFeedback < ActiveRecord::Migration[7.2]
  def change
    add_column :feedback, :read_at, :datetime
  end
end
