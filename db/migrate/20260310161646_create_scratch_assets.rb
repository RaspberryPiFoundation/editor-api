class CreateScratchAssets < ActiveRecord::Migration[7.2]
  def change
    create_table :scratch_assets, id: :uuid do |t|
      t.string :filename, null: false
      t.index :filename, unique: true

      t.timestamps
    end
  end
end
