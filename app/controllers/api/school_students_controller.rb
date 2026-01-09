# frozen_string_literal: true

module Api
  class SchoolStudentsController < ApiController
    # This constant is the maximum batch size we can post to
    # profile in the create step. We can validate larger batches.
    MAX_BATCH_CREATION_SIZE = 50

    before_action :authorize_user
    load_and_authorize_resource :school
    authorize_resource :school_student, class: false

    before_action :create_safeguarding_flags

    def index
      result = SchoolStudent::List.call(school: @school, token: current_user.token)

      if result.success?
        @school_students = result[:school_students]
        render :index, formats: [:json], status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def create
      result = SchoolStudent::Create.call(
        school: @school, school_student_params:, token: current_user.token
      )

      if result.success?
        head :no_content
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def create_batch
      if school_students_params.blank?
        render json: {
                 error: StandardError,
                 error_type: :unprocessable_entity
               },
               status: :unprocessable_entity
        return
      end

      students = StudentHelpers.normalise_nil_values_to_empty_strings(school_students_params)

      # We validate the entire batch here in one go and then, if the validation succeeds,
      # feed the batch to Profile in chunks of 50.
      validation_result = SchoolStudent::ValidateBatch.call(
        school: @school, students: students, token: current_user.token
      )

      if validation_result.failure?
        render json: {
          error: validation_result[:error],
          error_type: validation_result[:error_type]
        }, status: :unprocessable_entity
        return
      end

      # If we get this far, validation of the entire batch succeeded, so we enqueue it in chunks
      begin
        enqueue_batches(students)
      rescue StandardError => e
        Rails.logger.error "Failed to enqueue GoodJob Batch: #{e}"
        render json: { error: e, error_type: :batch_error }, status: :unprocessable_entity
        return
      end

      # We enqueued everything! Yay!
      render :create_batch, formats: [:json], status: :accepted
    end

    # This method takes a large list of students to insert and enqueues a GoodJob
    # Batch to insert them, 50 at a time. We use a GoodJob::Batch to enqueue the
    # set of jobs atomically.
    #
    # This method will throw an error if any batch fails to enqueue, so callers
    # should assume the entire student import has failed.
    def enqueue_batches(students)
      # Raise if a batch is already in progress for this school.
      raise ConcurrencyExceededForSchool if @school.import_in_progress?

      @batch = GoodJob::Batch.new(description: @school.id)
      @batch.enqueue do
        students.each_slice(MAX_BATCH_CREATION_SIZE) do |student_batch|
          SchoolStudent::CreateBatch.call(
            school: @school, school_students_params: student_batch, token: current_user.token
          )
        end
      end

      UserJob.create!(user_id: current_user.id, good_job_batch_id: @batch.id)
      Rails.logger.info("Batch #{@batch.id} enqueued successfully with school identifier #{@school.id}!")
    end

    def update
      result = SchoolStudent::Update.call(
        school: @school, student_id: params[:id], school_student_params:, token: current_user.token
      )

      if result.success?
        head :no_content
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def destroy
      remove_students([params[:id]])
    end

    def destroy_batch
      # DELETE /api/schools/:school_id/students/batch
      # Params: { student_ids: ["uuid1", "uuid2", ...] }
      #
      # Returns 200 OK with one of:
      # - Success: { results: [{ user_id: "..." }, ...] }
      # - Partial failure: { results: [...], error: "N student(s) failed to be removed" }
      #
      # Each result may contain:
      # - { user_id:, error: } - deletion failed
      # - { user_id:, skipped:, reason: } - student skipped (e.g., not in this school)
      # - { user_id: } - deletion succeeded

      student_ids = student_ids_params

      if student_ids.blank?
        render json: {
                 error: 'No student IDs provided',
                 error_type: :unprocessable_entity
               },
               status: :unprocessable_entity
        return
      end

      # Remove duplicates to avoid redundant processing
      unique_student_ids = student_ids.uniq
      remove_students(unique_student_ids)
    end

    private

    def remove_students(student_ids)
      service = StudentRemovalService.new(
        students: student_ids,
        school: @school,
        remove_from_profile: true,
        token: current_user.token
      )

      results = service.remove_students

      # Check if any errors occurred
      errors = results.select { |r| r[:error] }
      if errors.any?
        render json: {
          results: results,
          error: "#{errors.size} student(s) failed to be removed"
        }, status: :ok
      else
        render json: { results: results }, status: :ok
      end
    end

    def school_student_params
      params.require(:school_student).permit(:username, :password, :name)
    end

    def school_students_params
      school_students = params.require(:school_students)

      school_students.filter_map do |student|
        next if student.blank?

        student.permit(:username, :password, :name).to_h.with_indifferent_access
      end
    end

    def student_ids_params
      params.fetch(:student_ids, [])
    end

    def create_safeguarding_flags
      create_teacher_safeguarding_flag
      create_owner_safeguarding_flag
    end

    def create_teacher_safeguarding_flag
      return unless current_user.school_teacher?(@school)

      ProfileApiClient.create_safeguarding_flag(
        token: current_user.token,
        flag: ProfileApiClient::SAFEGUARDING_FLAGS[:teacher],
        email: current_user.email
      )
    end

    def create_owner_safeguarding_flag
      return unless current_user.school_owner?(@school)

      ProfileApiClient.create_safeguarding_flag(
        token: current_user.token,
        flag: ProfileApiClient::SAFEGUARDING_FLAGS[:owner],
        email: current_user.email
      )
    end
  end
end
