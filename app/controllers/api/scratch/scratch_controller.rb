# frozen_string_literal: true

module Api
  module Scratch
    class ScratchController < ApiController
      include IdentifiableByCookie

      before_action :authorize_user
      before_action :check_scratch_feature

      def check_scratch_feature
        return if current_user.nil?

        school = current_user&.schools&.first
        return if Flipper.enabled?(:cat_mode, school)

        raise ActiveRecord::RecordNotFound, 'Not Found'
      end
    end
  end
end
