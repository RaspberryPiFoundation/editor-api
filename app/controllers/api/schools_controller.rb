# frozen_string_literal: true

module Api
  class SchoolsController < ApiController
    before_action :authorize_user, only: %i[create]

    def create
      school_hash = school_params.merge(owner_id: current_user.id)
      result = School::Create.call(school_hash:)

      if result.success?
        @school = result[:school]
        render :show, formats: [:json]
      else
        render json: { error: result[:error] }, status: :unprocessable_entity
      end
    end

    private

    def school_params
      params.require(:school).permit(
        :name,
        :organisation_id,
        :address_line_1, # rubocop:disable Naming/VariableNumber
        :address_line_2, # rubocop:disable Naming/VariableNumber
        :municipality,
        :administrative_area,
        :postal_code,
        :country_code
      )
    end
  end
end
