# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Archiving a lesson', type: :request do
  before do
    stub_hydra_public_api(user_index: owner_index)
    stub_user_info_api
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:lesson) { create(:lesson, user_id: owner_id) }
  let(:owner_index) { user_index_by_role('school-owner') }
  let(:owner_id) { user_id_by_index(owner_index) }
  # let!(:role) { create(:owner_role, user_id: school_owner_id) }

  it 'responds 204 No Content' do
    delete("/api/lessons/#{lesson.id}", headers:)
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 204 No Content if the lesson is already archived' do
    lesson.archive!

    delete("/api/lessons/#{lesson.id}", headers:)
    expect(response).to have_http_status(:no_content)
  end

  it 'archives the lesson' do
    delete("/api/lessons/#{lesson.id}", headers:)
    expect(lesson.reload.archived?).to be(true)
  end

  it 'unarchives the lesson when the ?undo=true query parameter is set' do
    lesson.archive!

    delete("/api/lessons/#{lesson.id}?undo=true", headers:)
    expect(lesson.reload.archived?).to be(false)
  end

  it 'responds 401 Unauthorized when no token is given' do
    delete "/api/lessons/#{lesson.id}"
    expect(response).to have_http_status(:unauthorized)
  end

  it "responds 403 Forbidden when the user is not the lesson's owner" do
    lesson.update!(user_id: SecureRandom.uuid)

    delete("/api/lessons/#{lesson.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  context 'when the lesson is associated with a school (library)' do
    let(:school) { create(:school) }
    let!(:lesson) { create(:lesson, school:, visibility: 'teachers') }

    it 'responds 204 No Content when the user is a school-owner' do
      create(:owner_role, school:, user_id: owner_id)
      delete("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:no_content)
    end

    it "responds 403 Forbidden when the user a school-owner but visibility is 'private'" do
      create(:owner_role, school:, user_id: owner_id)
      lesson.update!(visibility: 'private')

      delete("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 403 Forbidden when the user is another school-teacher in the school' do
      stub_hydra_public_api(user_index: user_index_by_role('school-teacher'))
      lesson.update!(user_id: SecureRandom.uuid)

      delete("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 403 Forbidden when the user is a school-student' do
      stub_hydra_public_api(user_index: user_index_by_role('school-student'))

      delete("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
