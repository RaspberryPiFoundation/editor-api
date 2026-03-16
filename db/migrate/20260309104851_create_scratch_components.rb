class CreateScratchComponents < ActiveRecord::Migration[7.2]
  def change
    create_table :scratch_components, id: :uuid do |t|
      t.jsonb :content
      t.references :project, null: false, foreign_key: true, type: :uuid, index: { unique: true }

      t.timestamps
    end
  end
end
