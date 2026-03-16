class CreateScratchAssets < ActiveRecord::Migration[7.2]
  def change
    create_table :scratch_assets, id: :uuid do |t|
      t.string :filename

      t.timestamps
    end
  end
end
