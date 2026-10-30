# frozen_string_literal: true

module Api
  class FriendlyErrorMessagesController < ApiController
    before_action :authorize_user
    skip_authorization_check only: :show

    def show
      render json: { result: 'test' }
    end
  end
end
