# frozen_string_literal: true

module Api
  class SchoolEmailDomainsController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :school
    authorize_resource :school_email_domain, class: false

    def index
      render json: school_email_domains, status: :ok
    end

    def create
      result = SchoolEmailDomain::Create.call(school: @school, domain: school_email_domain_params[:domain], token: current_user.token)
      if result.success?
        render json: { domain: result[:school_email_domain].domain }, status: :created
      else
        render json: { error: result[:error] }, status: :unprocessable_content
      end
    end

    private

    def school_email_domains
      @school.school_email_domains.order(:created_at).pluck(:domain)
    end

    def school_email_domain_params
      params.expect(school_email_domain: [:domain])
    end
  end
end
