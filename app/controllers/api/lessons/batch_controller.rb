# frozen_string_literal: true

module Api
  module Lessons
    class BatchController < ApiController
      include RemixSelection
      include LessonCreation

      before_action :authorize_user
      before_action :verify_school_class_belongs_to_school
      before_action :authorize_lesson_projects!
      before_action :authorize_source_projects!

      def create_batch
        authorize_blank_lesson_batch! unless lesson_projects?
        raise ParameterError, 'lesson_projects cannot be blank' unless lesson_projects?

        @results = Lesson::CreateBatch.call(
          lessons_params: batch_lessons_params,
          source_projects: batch_source_projects
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

      def batch_lessons_params
        @batch_lessons_params ||= params[:lesson_projects].map { |lesson_params| create_batch_params(lesson_params) }
      end

      def batch_source_projects
        batch_lessons_params.each_index.map { |index| source_project_for(index) }
      end

      def source_project_for(index)
        @source_project_by_index ||= {}
        return @source_project_by_index[index] if @source_project_by_index.key?(index)

        lesson_params = batch_lessons_params[index]
        @source_project_by_index[index] = find_source_project!(
          lesson_params[:source_project_identifier],
          lesson_params.dig(:project_attributes, :locale)
        )
      end

      def create_batch_params(lesson_project)
        lesson_project
          .permit(*LESSON_ATTRIBUTES, :origin_identifier, :source_project_identifier, project_attributes: PROJECT_ATTRIBUTES)
          .merge(user_id: current_user.id)
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

      def authorize_source_projects!
        return unless lesson_projects?

        batch_lessons_params.each_index do |index|
          source_project = source_project_for(index)
          authorize! :show, source_project if source_project
        end
      end

      def authorize_blank_lesson_batch!
        authorize! :create, Lesson.new(user_id: current_user.id)
      end
    end
  end
end
