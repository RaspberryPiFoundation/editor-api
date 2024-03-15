# frozen_string_literal: true

module SignInStubs
  # Use this method if you don't want to bother going through the login process
  # itself.
  # rubocop:disable RSpec/AnyInstance
  def stub_sign_in(user)
    allow_any_instance_of(AuthenticationHelper).to receive(:current_user).and_return(user)
  end
  # rubocop:enable RSpec/AnyInstance

  def stub_auth_for(user)
    OmniAuth.config.add_mock(:rpi, uid: user.id, extra: { raw_info: user.serializable_hash(except: :id) })
  end

  # This method goes through the login process properly.  In system specs, you
  # need to have visited the page with the "Log in" link before calling this.
  # In request specs, we just post directly to `/auth/rpi`, so this can be
  # called without any prep.
  def sign_in(user)
    stub_auth_for(user)

    # This is a bit grotty, but see if we can call `find_link` (from Capybara,
    # i.e. system specs) first, and then if that fails fall back to using
    # `post` which is available in request specs.
    begin
      find_button('Log in', match: :first).click
    rescue NoMethodError
      post '/auth/rpi'
      follow_redirect!
    end
  end
end
