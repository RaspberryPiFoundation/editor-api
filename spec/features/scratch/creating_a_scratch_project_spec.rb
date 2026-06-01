# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a Scratch project (remixing)', type: :request do
  let(:pending_asset_filename) { 'pending.png' }
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:) }
  let(:headers) do
    {
      'Authorization' => UserProfileMock::TOKEN,
      'Origin' => 'editor.com'
    }
  end
  let(:request_query) { { original_id: original_project.identifier, is_remix: '1' } }
  let(:scratch_project) do
    {
      meta: { semver: '3.0.0' },
      targets: ['updated target'],
      monitors: [],
      extensions: ['pen']
    }
  end
  let(:lesson) { create(:lesson, school:, user_id: teacher.id) }
  let(:original_project) do
    create(
      :project,
      school:,
      lesson:,
      user_id: teacher.id,
      project_type: Project::Types::CODE_EDITOR_SCRATCH,
      locale: nil
    )
  end

  before do
    mock_phrase_generation('new-project-id')
    create(:scratch_component, project: original_project)
  end

  def make_request(query: request_query, request_headers: headers, request_params: scratch_project)
    post(
      "/api/scratch/projects?#{Rack::Utils.build_query(query)}",
      params: request_params,
      headers: request_headers,
      as: :json
    )
  end

  it 'responds 401 Unauthorized when no Authorization header is provided' do
    make_request(request_headers: {})

    expect(response).to have_http_status(:unauthorized)
  end

  it 'responds 404 Not Found when user is not part of a school' do
    user = create(:user)
    authenticated_in_hydra_as(user)

    make_request

    expect(response).to have_http_status(:not_found)
  end

  context 'when authenticated and part of a school' do
    before do
      authenticated_in_hydra_as(teacher)
    end

    it 'responds 403 Forbidden when not remixing' do
      make_request(query: request_query.merge(is_remix: '0'))

      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 403 Forbidden when original_id is missing' do
      make_request(query: { is_remix: '1' })

      expect(response).to have_http_status(:forbidden)
    end

    it 'responds 404 Not Found when original project does not exist' do
      make_request(query: { original_id: 'no-such-project', is_remix: '1' })

      expect(response).to have_http_status(:not_found)
    end

    it 'responds 404 Not Found when the original project is not a Scratch project' do
      non_scratch_project = create(:project, school:, lesson:, user_id: teacher.id, locale: nil)

      make_request(query: { original_id: non_scratch_project.identifier, is_remix: '1' })

      expect(response).to have_http_status(:not_found)
    end

    it 'responds 401 Unauthorized when the user cannot access the original project' do
      inaccessible_project = create(:project, project_type: Project::Types::CODE_EDITOR_SCRATCH, locale: nil)
      create(:scratch_component, project: inaccessible_project)

      make_request(query: { original_id: inaccessible_project.identifier, is_remix: '1' })

      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds 400 Bad Request when no Scratch content is submitted' do
      make_request(request_params: {})

      expect(response).to have_http_status(:bad_request)
    end

    it 'creates a remix, associates it to the current user, and returns the new identifier' do
      expect { make_request }.to change(Project, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        'status' => 'ok',
        'content-name' => 'new-project-id'
      )

      remixed_project = Project.find_by!(identifier: 'new-project-id')
      expect(remixed_project.user_id).to eq(teacher.id)
      expect(remixed_project.remixed_from_id).to eq(original_project.id)
      expect(remixed_project.lesson_id).to be_nil
      expect(remixed_project.scratch_component.content.to_h).to eq(scratch_project.deep_stringify_keys)
    end

    it 'moves the current user pending original-project assets onto the new remix' do
      student = create(:student, school:)
      school_class = create(:school_class, school:, teacher_ids: [teacher.id])
      create(:class_student, school_class:, student_id: student.id)
      original_project.update!(lesson: create(:lesson, school:, school_class:, user_id: teacher.id, visibility: 'students'))
      create_uploaded_scratch_asset(
        filename: pending_asset_filename,
        project: original_project,
        uploaded_user_id: student.id,
        body: 'pending-body'
      )
      authenticated_in_hydra_as(student)

      expect { make_request }.to change(Project, :count).by(1)

      remixed_project = Project.find_by!(identifier: 'new-project-id')
      expect(
        ScratchAsset.find_by!(filename: pending_asset_filename, project: remixed_project, uploaded_user_id: student.id).file.download
      ).to eq('pending-body')
      expect(
        ScratchAsset.find_by(filename: pending_asset_filename, project: original_project, uploaded_user_id: student.id)
      ).to be_nil
    end

    it 'updates the existing remix instead of creating a duplicate' do
      student = create(:student, school:)
      school_class = create(:school_class, school:, teacher_ids: [teacher.id])
      create(:class_student, school_class:, student_id: student.id)
      original_project.update!(lesson: create(:lesson, school:, school_class:, user_id: teacher.id, visibility: 'students'))
      existing_remix = create(
        :project,
        school:,
        user_id: student.id,
        remixed_from_id: original_project.id,
        project_type: Project::Types::CODE_EDITOR_SCRATCH,
        locale: nil
      )
      create(:scratch_component, project: existing_remix, content: { targets: ['old target'], monitors: [], extensions: [], meta: {} })
      create_uploaded_scratch_asset(
        filename: pending_asset_filename,
        project: original_project,
        uploaded_user_id: student.id,
        body: 'pending-body'
      )
      authenticated_in_hydra_as(student)

      expect { make_request }.not_to change(Project, :count)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        'status' => 'ok',
        'content-name' => existing_remix.identifier
      )
      expect(existing_remix.reload.scratch_component.content.to_h).to eq(scratch_project.deep_stringify_keys)
      expect(
        ScratchAsset.find_by!(filename: pending_asset_filename, project: existing_remix, uploaded_user_id: student.id).file.download
      ).to eq('pending-body')
      expect(
        ScratchAsset.find_by(filename: pending_asset_filename, project: original_project, uploaded_user_id: student.id)
      ).to be_nil
    end

    it 'keeps the existing remix asset when reassignment finds the same filename there already' do
      student = create(:student, school:)
      school_class = create(:school_class, school:, teacher_ids: [teacher.id])
      create(:class_student, school_class:, student_id: student.id)
      original_project.update!(lesson: create(:lesson, school:, school_class:, user_id: teacher.id, visibility: 'students'))
      existing_remix = create(
        :project,
        school:,
        user_id: student.id,
        remixed_from_id: original_project.id,
        project_type: Project::Types::CODE_EDITOR_SCRATCH,
        locale: nil
      )
      create(:scratch_component, project: existing_remix, content: { targets: ['old target'], monitors: [], extensions: [], meta: {} })
      create_uploaded_scratch_asset(
        filename: pending_asset_filename,
        project: original_project,
        uploaded_user_id: student.id,
        body: 'source-body'
      )
      destination_asset = create_uploaded_scratch_asset(
        filename: pending_asset_filename,
        project: existing_remix,
        uploaded_user_id: student.id,
        body: 'destination-body'
      )
      authenticated_in_hydra_as(student)

      expect { make_request }.not_to change(Project, :count)

      expect(destination_asset.reload.file.download).to eq('destination-body')
      expect(
        ScratchAsset.find_by(filename: pending_asset_filename, project: original_project, uploaded_user_id: student.id)
      ).to be_nil
    end
  end

  def create_uploaded_scratch_asset(filename:, project:, uploaded_user_id:, body:, content_type: 'image/png')
    ScratchAsset.create!(filename:, project:, uploaded_user_id:).tap do |asset|
      asset.file.attach(io: StringIO.new(body), filename:, content_type:)
    end
  end
end
