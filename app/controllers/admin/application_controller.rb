# All Administrate controllers inherit from this
# `Administrate::ApplicationController`, making it the ideal place to put
# authentication logic or other before_actions.
#
# If you want to add pagination or other controller-level concerns,
# you're free to overwrite the RESTful controller actions.
module Admin
  class ApplicationController < Administrate::ApplicationController
    # include RpiAuth::Controllers::CurrentUser
    include AuthenticationHelper
    # include Identifiable

    before_action :authenticate_admin

    helper_method :current_user

    def authenticate_admin
      puts current_user.inspect
      redirect_to '/', alert: 'Not authorized.' unless current_user&.admin?
    end

    # Override this value to specify the number of elements to display at a time
    # on index pages. Defaults to 20.
    # def records_per_page
    #   params[:per_page] || 20
    # end
  end
end
