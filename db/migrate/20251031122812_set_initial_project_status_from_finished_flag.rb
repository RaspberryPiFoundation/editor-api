class SetInitialProjectStatusFromFinishedFlag < ActiveRecord::Migration[7.2]
  def up
    SchoolProject.find_each do |school_project|
      next if school_project.school_project_transitions.any?

      initial_state = school_project.finished ? 'complete' : 'unsubmitted'
      SchoolProjectTransition.create!(
        school_project: school_project,
        from_state: '',
        to_state: initial_state,
        metadata: {},
        sort_key: 0,
        most_recent: true
      )
    end
  end

  def down
    SchoolProjectTransition.delete_all
  end
end
