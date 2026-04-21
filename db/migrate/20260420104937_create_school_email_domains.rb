# frozen_string_literal: true

class CreateSchoolEmailDomains < ActiveRecord::Migration[7.2]
  def change
    create_table :school_email_domains, id: :uuid do |t|
      t.references :school, null: false, foreign_key: true, type: :uuid
      t.string :domain, null: false

      t.timestamps
    end

    add_index :school_email_domains, %i[school_id domain], unique: true
  end
end
