# frozen_string_literal: true

class SchoolProject < ApplicationRecord
  belongs_to :school
  belongs_to :project
  has_many :feedback, dependent: :destroy
  has_many :school_project_transitions, autosave: false, dependent: :destroy

  include Statesman::Adapters::ActiveRecordQueries[
    transition_class: ::SchoolProjectTransition,
    initial_state: :unsubmitted
  ]

  # Experience CS marks Scratch projects complete by flipping school_projects.finished
  # (Concept::SchoolProject::SetFinished, bypassing the state machine). That's invisible
  # to the state-machine after_transition callbacks, so without this hook the parent
  # lesson's Lesson__c.numberofcompletedprojects__c in Salesforce would never reflect
  # Experience CS completions. The job reads Lesson#finished_projects_count live.
  after_commit :enqueue_salesforce_lesson_sync, on: :update, if: :saved_change_to_finished?

  def lesson
    project.lesson || project.parent&.lesson
  end

  def status
    state_machine.current_state
  end

  def transition_status_to!(new_status, user_id)
    state_machine.transition_to!(new_status, metadata: { changed_by: user_id })
  end

  def unread_feedback?
    feedback.exists?(read_at: nil)
  end

  def recalculate_lesson_submitted_projects_count!(_transition = nil)
    lesson&.recalculate_submitted_projects_count!
  end

  def enqueue_salesforce_lesson_sync(_transition = nil)
    return unless FeatureFlags.salesforce_sync?

    lesson_id = lesson&.id
    return if lesson_id.blank?

    Salesforce::LessonSyncJob.perform_later(lesson_id:)
  end

  # Add convenience methods for each state
  def unsubmitted?
    state_machine.in_state?(:unsubmitted)
  end

  def submitted?
    state_machine.in_state?(:submitted)
  end

  def complete?
    state_machine.in_state?(:complete)
  end

  def returned?
    state_machine.in_state?(:returned)
  end

  delegate :can_transition_to?, :history, :in_state?, to: :state_machine

  private

  def state_machine
    @state_machine ||= SchoolProjectStateMachine.new(self, transition_class: SchoolProjectTransition)
  end
end
