# frozen_string_literal: true

module Api
  class SchoolsController < ApiController
    before_action :authorize_user
    load_and_authorize_resource
    skip_load_and_authorize_resource only: :import

    def index
      @schools = School.accessible_by(current_ability)
      render :index, formats: [:json], status: :ok
    end

    def show
      render :show, formats: [:json], status: :ok
    end

    def create
      result = School::Create.call(school_params:, creator_id: current_user.id)

      if result.success?
        @school = result[:school]
        render :show, formats: [:json], status: :created
      else
        render json: {
          error: result[:error],
          error_types: result[:error_types]
        }, status: :unprocessable_entity
      end
    end

    def update
      school = School.find(params[:id])
      result = School::Update.call(school:, school_params:)

      if result.success?
        @school = result[:school]
        render :show, formats: [:json], status: :ok
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def destroy
      result = School::Delete.call(school_id: params[:id])

      if result.success?
        head :no_content
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    def import
      authorize! :import, School

      if params[:csv_file].blank?
        render json: { error: SchoolImportError.format_error(:csv_file_required, 'CSV file is required') },
               status: :unprocessable_entity
        return
      end

      result = School::ImportBatch.call(
        csv_file: params[:csv_file],
        current_user: current_user
      )

      if result.success?
        @job_id = result[:job_id]
        @total_schools = result[:total_schools]
        render :import, formats: [:json], status: :accepted
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    private

    def school_params
      params.require(:school).permit(
        :name,
        :website,
        :reference,
        :district_name,
        :district_nces_id,
        :school_roll_number,
        :address_line_1,
        :address_line_2,
        :municipality,
        :administrative_area,
        :postal_code,
        :country_code,
        :creator_role,
        :creator_department,
        :creator_agree_authority,
        :creator_agree_terms_and_conditions,
        :creator_agree_to_ux_contact,
        :creator_agree_responsible_safeguarding,
        :user_origin
      )
    end
  end
end
