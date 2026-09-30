# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Code Editor education page' do
  around do |example|
    ClimateControl.modify(
      EDITOR_APP_HOSTS: 'editor.example.com',
      EDITOR_PUBLIC_URL: 'https://classroom.example.com'
    ) { example.run }
  end

  it 'sends teachers to their school in Code Classroom' do
    get 'http://editor.example.com/en/education'
    expect(response).to redirect_to('https://classroom.example.com/en/school')
  end

  it 'keeps the reader in their own language' do
    get 'http://editor.example.com/fr-FR/education'
    expect(response).to redirect_to('https://classroom.example.com/fr-FR/school')
  end
end
