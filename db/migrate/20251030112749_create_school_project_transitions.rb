class CreateSchoolProjectTransitions < ActiveRecord::Migration[7.2]
  def change
    create_table :school_project_transitions do |t|
      t.string :from_state, null: false
      t.string :to_state, null: false
      t.text :metadata, default: "{}"
      t.integer :sort_key, null: false
      t.uuid :school_project_id, null: false
      t.boolean :most_recent, null: false

      # If you decide not to include an updated timestamp column in your transition
      # table, you'll need to configure the `updated_timestamp_column` setting in your
      # migration class.
      t.timestamps null: false
    end

    # Foreign keys are optional, but highly recommended
    add_foreign_key :school_project_transitions, :school_projects

    add_index(:school_project_transitions,
              %i(school_project_id sort_key),
              unique: true,
              name: "index_school_project_transitions_parent_sort")
    add_index(:school_project_transitions,
              %i(school_project_id most_recent),
              unique: true,
              where: "most_recent",
              name: "index_school_project_transitions_parent_most_recent")
  end
end
