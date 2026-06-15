# frozen_string_literal: true

module Api
  class SchoolEmailDomainsController < ApiController
    before_action :authorize_user
    load_and_authorize_resource :school
    authorize_resource :school_email_domain, class: false

    def index
      render json: school_email_domains, status: :ok
    end

    private

    def school_email_domains
      @school.school_email_domains.order(:created_at).pluck(:domain)
    end
  end
end
