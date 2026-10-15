# frozen_string_literal: true

module EditorApp
  class FooterComponent < BaseComponent
    HELP_URL = 'https://help.editor.raspberrypi.org/hc/en-us'
    FEEDBACK_URL = 'https://form.raspberrypi.org/f/code-editor-feedback'
    TERMS_URL = 'https://my.raspberrypi.org/code-classroom-terms'
    SAFEGUARDING_URL = 'https://www.raspberrypi.org/safeguarding/'
    ACCESSIBILITY_URL = 'https://www.raspberrypi.org/accessibility/'
    PRIVACY_URL = 'https://www.raspberrypi.org/privacy/'
    COOKIES_URL = 'https://www.raspberrypi.org/cookies/'
    REPORT_CONCERN_URL = 'https://form.raspberrypi.org/f/report-concern-code-editor-for-education'

    attr_reader :user, :show_feedback_link

    def initialize(user: nil, show_feedback_link: false)
      super()
      @user = user
      @show_feedback_link = show_feedback_link
    end

    def school
      @school ||= user&.schools&.active&.first
    end

    def report_concern_url
      "#{REPORT_CONCERN_URL}?tfa_2019=#{user.id}&tfa_2021=#{school.id}"
    end

    def links
      [
        [t('editor_app.footer.help'), HELP_URL],
        ([t('editor_app.footer.feedback'), FEEDBACK_URL] if show_feedback_link),
        [t('editor_app.footer.terms_and_conditions'), TERMS_URL],
        [t('editor_app.footer.safeguarding'), SAFEGUARDING_URL],
        [t('editor_app.footer.accessibility'), ACCESSIBILITY_URL],
        [t('editor_app.footer.privacy'), PRIVACY_URL],
        [t('editor_app.footer.cookies'), COOKIES_URL]
      ].compact
    end
  end
end
