# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin school classes', type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:school) { create(:school) }
  let(:teacher) { create(:user, name: 'Tariq Teacher', email: 'teacher@example.com') }
  let(:other_teacher) { create(:user, name: 'Olivia Teacher', email: 'olivia@example.com') }
  let(:school_class) { create(:school_class, school:, teacher_ids: [teacher.id, other_teacher.id]) }

  before do
    allow(User).to receive(:from_omniauth).and_return(admin_user)
    get '/auth/callback'
    allow(User).to receive(:from_userinfo).with(ids: contain_exactly(teacher.id, other_teacher.id)).and_return([other_teacher, teacher])
  end

  it 'displays each teacher name and email using a single batch lookup' do
    get admin_school_class_path(school_class)

    expect(response).to have_http_status(:success)
    expect(response.body).to include('Tariq Teacher (teacher@example.com)', 'Olivia Teacher (olivia@example.com)')
    expect(response.body).not_to include(teacher.id, other_teacher.id)
    expect(User).to have_received(:from_userinfo).with(ids: contain_exactly(teacher.id, other_teacher.id)).once
  end

  it 'falls back to the UUID when a teacher is missing from user info' do
    allow(User).to receive(:from_userinfo).and_return([teacher])

    get admin_school_class_path(school_class)

    expect(response).to have_http_status(:success)
    expect(response.body).to include('Tariq Teacher (teacher@example.com)', other_teacher.id)
  end

  it 'renders an empty teacher list without looking up users' do
    school_class.teachers.destroy_all

    get admin_school_class_path(school_class)

    expect(response).to have_http_status(:success)
    expect(User).not_to have_received(:from_userinfo)
  end
end
