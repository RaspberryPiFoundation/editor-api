# frozen_string_literal: true

module Api
  module Lessons
    class BatchController < ApiController
      include RemixSelection
      include LessonCreation

      before_action :authorize_user
      before_action :verify_school_class_belongs_to_school
      before_action :verify_can_create_scratch_projects
      before_action :authorize_lesson_projects!

      def create_batch
        raise ParameterError, 'lesson_projects cannot be blank' unless lesson_projects?

        @results = Lesson::CreateBatch.call(
          lessons_params: batch_lessons_params
        )
        @user = current_user
        @results.select(&:success?).each { |result| track_project_event('Project - Created', result[:lesson].project) }
        render :create_batch, formats: [:json], status: :created
      end

      private

      def verify_school_class_belongs_to_school
        return unless lesson_projects?

        params[:lesson_projects].each { |lesson_params| verify_lesson_school_class!(lesson_params) }
      end

      def verify_can_create_scratch_projects
        return unless lesson_projects?

        scratch_project_params = params[:lesson_projects].find { |lesson_params| scratch_project?(lesson_params) }
        return unless scratch_project_params

        verify_lesson_scratch!(scratch_project_params)
      end

      def batch_lessons_params
        @batch_lessons_params ||= params[:lesson_projects].map { |lesson_params| create_batch_params(lesson_params) }
      end

      def create_batch_params(lesson_project)
        lesson_project.permit(*LESSON_ATTRIBUTES, :origin_identifier, project_attributes: PROJECT_ATTRIBUTES).merge(user_id: current_user.id)
      end

      def lesson_projects?
        projects = params[:lesson_projects]
        return false unless projects.is_a?(Array)

        projects.any?(&:present?)
      end

      def authorize_lesson_projects!
        return unless lesson_projects?

        batch_lessons_params.each do |lesson_params|
          authorize! :create, Lesson.new(lesson_params.slice(:school_id, :school_class_id, :user_id))
        end
      end
    end
  end
end
