# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditorApp::SecondaryNavComponent, type: :component do
  subject(:rendered) do
    with_controller_class(EditorApp::HomeController) { render_inline(component) }
  end

  around do |example|
    ClimateControl.modify(EDITOR_PUBLIC_URL: 'https://classroom.example.com') { example.run }
  end

  let(:component) { described_class.new(current_path: '/en', user: nil) }

  it 'links to the home page and the education page' do
    expect(rendered.css('a').pluck(:href)).to eq(['/en', '/en/education'])
  end

  it 'marks the current page as active' do
    expect(rendered.css('.secondary-nav__link--active').attr('href').value).to eq('/en')
  end

  context 'when the page is not the home page' do
    let(:component) { described_class.new(current_path: '/en/projects', user: nil) }

    it 'does not render, as the nav belongs to the home page' do
      expect(rendered.to_html).to be_blank
    end
  end

  context 'when a user with no school is signed in' do
    let(:component) { described_class.new(current_path: '/en', user: create(:user)) }

    it 'offers their projects' do
      expect(rendered.css('a').pluck(:href)).to include('/en/projects')
    end

    it 'does not offer a school they are not part of' do
      expect(rendered.to_html).not_to include('/en/school')
    end
  end

  context 'when a school teacher is signed in' do
    let(:component) { described_class.new(current_path: '/en', user: create(:teacher, school: create(:school))) }

    it 'offers their school in Code Classroom' do
      expect(rendered.css('a').pluck(:href)).to include('https://classroom.example.com/en/school')
    end
  end

  context 'when a school student is signed in' do
    let(:component) { described_class.new(current_path: '/en', user: create(:student, school: create(:school))) }

    it 'does not offer the project index, which students cannot use' do
      expect(rendered.to_html).not_to include('/en/projects')
    end
  end
end
