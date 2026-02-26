# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Destroying a lesson', type: :request do
  before do
    authenticated_in_hydra_as(owner)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:lesson) { create(:lesson, user_id: owner.id) }
  let(:owner_id) { SecureRandom.uuid }
  let(:teacher) { create(:teacher, school:) }
  let(:owner) { create(:owner, school:) }
  let(:school) { create(:school) }

  it 'responds 204 No Content' do
    delete("/api/lessons/#{lesson.id}", headers:)
    expect(response).to have_http_status(:no_content)
  end

  it 'destroys the lesson' do
    lesson_id = lesson.id
    delete("/api/lessons/#{lesson_id}", headers:)
    expect(Lesson.exists?(lesson_id)).to be(false)
  end

  it 'destroys the associated project' do
    project_id = lesson.project.id
    delete("/api/lessons/#{lesson.id}", headers:)
    expect(Project.exists?(project_id)).to be(false)
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
    let!(:lesson) { create(:lesson, school:, visibility: 'teachers', user_id: teacher.id) }

    it 'responds 204 No Content when the user is a school-owner' do
      delete("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:no_content)
    end

    it "responds 403 Forbidden when the user a school-owner but visibility is 'private'" do
      lesson.update!(visibility: 'private')

      delete("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 403 Forbidden when the user is another school-teacher in the school' do
      teacher = create(:teacher, school:)
      authenticated_in_hydra_as(teacher)

      delete("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 403 Forbidden when the user is a school-student' do
      student = create(:student, school:)
      authenticated_in_hydra_as(student)

      delete("/api/lessons/#{lesson.id}", headers:)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
