# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditorApp::FooterComponent, type: :component do
  subject(:rendered) do
    with_controller_class(EditorApp::HomeController) { render_inline(component) }
  end

  let(:component) { described_class.new }

  it 'names the charity behind the editor' do
    expect(rendered.to_html).to include('registered charity 1129409')
  end

  it 'links to help, terms, safeguarding, accessibility, privacy and cookies' do
    expect(rendered.css('.footer__link').pluck(:href)).to eq(
      [
        described_class::HELP_URL,
        described_class::TERMS_URL,
        described_class::SAFEGUARDING_URL,
        described_class::ACCESSIBILITY_URL,
        described_class::PRIVACY_URL,
        described_class::COOKIES_URL
      ]
    )
  end

  it 'omits the feedback link unless it is asked for' do
    expect(rendered.to_html).not_to include(described_class::FEEDBACK_URL)
  end

  context 'when the feedback link is asked for' do
    let(:component) { described_class.new(show_feedback_link: true) }

    it 'offers it' do
      expect(rendered.css('.footer__link').pluck(:href)).to include(described_class::FEEDBACK_URL)
    end
  end

  context 'when a user with no school is signed in' do
    let(:component) { described_class.new(user: create(:user)) }

    it 'does not offer to report a safeguarding concern, which needs a school' do
      expect(rendered.to_html).not_to include('report-concern')
    end
  end

  context 'when a school teacher is signed in' do
    let(:school) { create(:school) }
    let(:teacher) { create(:teacher, school:) }
    let(:component) { described_class.new(user: teacher) }

    it 'offers to report a safeguarding concern' do
      expect(rendered.to_html).to include('Do you have a safeguarding concern?')
    end

    it 'identifies the user and their school to the concern form' do
      expect(rendered.css('.footer__link').pluck(:href))
        .to include("#{described_class::REPORT_CONCERN_URL}?tfa_2019=#{teacher.id}&tfa_2021=#{school.id}")
    end
  end
end
