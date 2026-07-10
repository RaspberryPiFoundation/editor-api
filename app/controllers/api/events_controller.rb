# frozen_string_literal: true

module Api
  class EventsController < ApiController
    before_action :authorize_user
    # Authenticated telemetry endpoint; authorize_user is the access boundary.
    skip_authorization_check only: :create

    def create
      event = Event.new(event_params.merge(user_id: current_user.id, time: Time.current))
      if event.save
        head :created
      else
        render json: { error: event.errors }, status: :unprocessable_content
      end
    end

    private

    def event_params
      params.expect(event: [:name, { properties: {} }])
    end
  end
end
