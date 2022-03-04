# frozen_string_literal: true

require 'rails_helper'

describe 'Projects API response' do
  let(:project) { create(:project) }

  before do
    view.stub(:project)
  end

  it 'includes the parent project name and identifier if a child' do
    render '/api/projects/show', formats: [:json], project: project
    puts(rendered)
  end
end
