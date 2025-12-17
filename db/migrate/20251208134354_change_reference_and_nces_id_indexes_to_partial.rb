# frozen_string_literal: true

class ChangeReferenceAndNcesIdIndexesToPartial < ActiveRecord::Migration[7.2]
  def change
    # Convert reference (UK URN) index to partial index
    # This allows rejected schools to release their URN for reuse
    remove_index :schools, :reference
    add_index :schools, :reference, unique: true, where: 'rejected_at IS NULL'

    # Convert district_nces_id (US NCES ID) index to partial index
    # This allows rejected schools to release their NCES ID for reuse
    remove_index :schools, :district_nces_id
    add_index :schools, :district_nces_id, unique: true, where: 'rejected_at IS NULL'
  end
end

