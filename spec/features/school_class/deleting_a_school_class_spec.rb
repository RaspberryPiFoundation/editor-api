# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Deleting a school class', type: :request do
  before do
    authenticate_as_school_owner(owner)
    stub_user_info_api_for(teacher)
  end

  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:school_class) { create(:school_class, teacher_id: teacher.id, school:) }
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:) }
  let(:owner) { create(:owner, school:) }

  it 'responds 204 No Content' do
    delete("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 204 No Content when the user is the class teacher' do
    authenticate_as_school_teacher(teacher)

    delete("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:no_content)
  end

  it 'responds 401 Unauthorized when no token is given' do
    delete "/api/schools/#{school.id}/classes/#{school_class.id}"
    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 403 Forbidden when the user is a school-owner for a different school' do
    school = create(:school, id: SecureRandom.uuid)
    school_class.update!(school_id: school.id)

    delete("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is not the school-teacher for the class' do
    teacher = create(:teacher, school:)
    authenticate_as_school_teacher(teacher)

    delete("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end

  it 'responds 403 Forbidden when the user is a school-student' do
    student = create(:student, school:)
    authenticated_in_hydra_as(student)

    delete("/api/schools/#{school.id}/classes/#{school_class.id}", headers:)
    expect(response).to have_http_status(:forbidden)
  end
end
