# frozen_string_literal: true

module Api
  class SchoolsController < ApiController
    before_action :authorize_user
    load_and_authorize_resource

    def index
      @schools = School.accessible_by(current_ability)
      render :index, formats: [:json], status: :ok
    end

    def show
      render :show, formats: [:json], status: :ok
    end

    def create
      result = School::Create.call(school_params:, token: current_user&.token)

      if result.success?
        @school = result[:school]
        render :show, formats: [:json], status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
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

    private

    def school_params
      params.require(:school).permit(
        :name,
        :reference,
        :address_line_1,
        :address_line_2,
        :municipality,
        :administrative_area,
        :postal_code,
        :country_code
      )
    end
  end
end
