# frozen_string_literal: true

class AddInstructionStepsToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :instruction_steps, :jsonb
  end
end
