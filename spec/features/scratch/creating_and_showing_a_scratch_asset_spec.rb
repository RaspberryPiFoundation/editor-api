# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Creating a Scratch asset', type: :request do
  let(:basename) { 'test_image_1' }
  let(:svg_filename) { 'test_svg_image.svg' }
  let(:format) { 'png' }
  let(:filename) { "#{basename}.#{format}" }
  let(:school) { create(:school) }
  let(:teacher) { create(:teacher, school:) }
  let(:project) { create_scratch_project(user_id: teacher.id) }
  let(:auth_headers) { { 'Authorization' => UserProfileMock::TOKEN } }
  let(:project_headers) { auth_headers.merge('X-Project-ID' => project.identifier) }

  describe 'GET #show' do
    it 'responds 400 Bad Request when X-Project-ID is not provided' do
      get '/api/scratch/assets/internalapi/asset/test_image_1.png/get/', headers: auth_headers

      expect(response).to have_http_status(:bad_request)
    end

    context 'when the user can view the project' do
      before do
        authenticated_in_hydra_as(teacher)
      end

      context 'when the asset is PNG' do
        before do
          create(:scratch_asset, :with_file, filename:, project:, asset_path: file_fixture(filename))
        end

        it 'serves the file with png content type' do
          get '/api/scratch/assets/internalapi/asset/test_image_1.png/get/', headers: project_headers

          follow_redirect! while response.redirect?

          expect(response.media_type).to eq('image/png')
        end
      end

      context 'when the asset is SVG' do
        # rubocop:disable RSpec/NestedGroups
        context 'when the asset belongs to the project' do
          before do
            create(:scratch_asset, :with_file, filename: svg_filename, project:, asset_path: file_fixture(svg_filename))
          end

          it 'serves the file with application/octet-stream content type' do
            get '/api/scratch/assets/internalapi/asset/test_svg_image.svg/get/', headers: project_headers

            follow_redirect! while response.redirect?

            expect(response.media_type).to eq('application/octet-stream')
          end
        end

        context 'when the asset is global' do
          before do
            create(:scratch_asset, :with_file, filename: svg_filename, project: nil, asset_path: file_fixture(svg_filename))
          end

          it 'serves the file with image/svg+xml content type' do
            get '/api/scratch/assets/internalapi/asset/test_svg_image.svg/get/', headers: project_headers

            follow_redirect! while response.redirect?

            expect(response.media_type).to eq('image/svg+xml')
          end
        end
        # rubocop:enable RSpec/NestedGroups
      end

      it 'falls back to a global asset when the project has no matching asset' do
        create_uploaded_scratch_asset(filename: 'library.png', project: nil, body: 'global-body')

        get '/api/scratch/assets/internalapi/asset/library.png/get/', headers: project_headers

        follow_redirect! while response.redirect?

        expect(response.body).to eq('global-body')
      end

      it 'does not expose assets from another project' do
        other_project = create_scratch_project(user_id: SecureRandom.uuid)
        create_uploaded_scratch_asset(filename: 'hidden.png', project: other_project, body: 'other-project-body')

        get '/api/scratch/assets/internalapi/asset/hidden.png/get/', headers: project_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the viewer is a student on the original project' do
      let(:school_class) { create(:school_class, school:, teacher_ids: [teacher.id]) }
      let(:student) { create(:student, school:) }
      let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id, visibility: 'students') }
      let(:teacher_project) { create_scratch_project(school:, lesson:, user_id: teacher.id) }
      let(:project_headers) { auth_headers.merge('X-Project-ID' => teacher_project.identifier) }

      before do
        authenticated_in_hydra_as(student)
        create(:class_student, school_class:, student_id: student.id)
      end

      it 'prefers the current student asset on the original project over the shared teacher asset' do
        create_uploaded_scratch_asset(filename: 'shared.png', project: teacher_project, body: 'teacher-body')
        create_uploaded_scratch_asset(filename: 'shared.png', project: teacher_project, uploaded_user_id: student.id, body: 'student-body')

        get '/api/scratch/assets/internalapi/asset/shared.png/get/', headers: project_headers

        follow_redirect! while response.redirect?

        expect(response.body).to eq('student-body')
      end

      it "does not expose another student's private asset on the original project" do
        other_student = create(:student, school:)
        create(:class_student, school_class:, student_id: other_student.id)
        create_uploaded_scratch_asset(filename: 'shared.png', project: teacher_project, body: 'teacher-body')
        create_uploaded_scratch_asset(
          filename: 'shared.png',
          project: teacher_project,
          uploaded_user_id: other_student.id,
          body: 'other-student-body'
        )

        get '/api/scratch/assets/internalapi/asset/shared.png/get/', headers: project_headers

        follow_redirect! while response.redirect?

        expect(response.body).to eq('teacher-body')
      end

      it 'does not prefer assets from an existing remix when reading through the original project' do
        student_remix = create_scratch_project(school:, user_id: student.id, remixed_from_id: teacher_project.id)
        create_uploaded_scratch_asset(filename: 'shared.png', project: teacher_project, body: 'teacher-body')
        create_uploaded_scratch_asset(filename: 'shared.png', project: student_remix, uploaded_user_id: student.id, body: 'remix-body')

        get '/api/scratch/assets/internalapi/asset/shared.png/get/', headers: project_headers

        follow_redirect! while response.redirect?

        expect(response.body).to eq('teacher-body')
      end
    end

    context 'when the project is a remix' do
      let(:school_class) { create(:school_class, school:, teacher_ids: [teacher.id]) }
      let(:student) { create(:student, school:) }
      let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id, visibility: 'students') }
      let(:teacher_project) { create_scratch_project(school:, lesson:, user_id: teacher.id) }
      let(:project) { create_scratch_project(school:, user_id: student.id, remixed_from_id: teacher_project.id) }

      before do
        authenticated_in_hydra_as(student)
        create(:class_student, school_class:, student_id: student.id)
      end

      it 'serves assets from an ancestor project' do
        create_uploaded_scratch_asset(filename: 'teacher_asset.png', project: teacher_project, body: 'ancestor-body')

        get '/api/scratch/assets/internalapi/asset/teacher_asset.png/get/', headers: project_headers

        follow_redirect! while response.redirect?

        expect(response.body).to eq('ancestor-body')
      end

      it 'serves assets from the current remix before ancestor or global assets' do
        create_uploaded_scratch_asset(filename: 'shared.png', project: teacher_project, body: 'ancestor-body')
        create_uploaded_scratch_asset(filename: 'shared.png', project:, body: 'current-body')
        create_uploaded_scratch_asset(filename: 'shared.png', project: nil, body: 'global-body')

        get '/api/scratch/assets/internalapi/asset/shared.png/get/', headers: project_headers

        follow_redirect! while response.redirect?

        expect(response.body).to eq('current-body')
        expect(response.media_type).to eq('image/png')
      end

      it 'still sees the current student asset on an ancestor project before the shared ancestor asset' do
        create_uploaded_scratch_asset(filename: 'shared.png', project: teacher_project, body: 'teacher-body')
        create_uploaded_scratch_asset(filename: 'shared.png', project: teacher_project, uploaded_user_id: student.id, body: 'student-body')

        get '/api/scratch/assets/internalapi/asset/shared.png/get/', headers: project_headers

        follow_redirect! while response.redirect?

        expect(response.body).to eq('student-body')
      end
    end
  end

  describe 'POST #create' do
    let(:upload) { File.binread(file_fixture(filename)) }
    let(:request_headers) do
      { 'Content-Type' => 'application/octet-stream', 'X-Project-ID' => project.identifier }.merge(auth_headers)
    end
    let(:make_request) do
      post '/api/scratch/assets/test_image_1.png', headers: request_headers, params: upload
    end

    context 'when a teacher is logged in' do
      before do
        authenticated_in_hydra_as(teacher)
      end

      it 'responds 400 Bad Request when X-Project-ID is not provided' do
        post '/api/scratch/assets/test_image_1.png',
             headers: { 'Content-Type' => 'application/octet-stream' }.merge(auth_headers),
             params: upload

        expect(response).to have_http_status(:bad_request)
      end

      it 'creates a new asset' do
        expect { make_request }.to change(ScratchAsset, :count).by(1)
      end

      it 'sets the filename on the asset' do
        make_request
        expect(ScratchAsset.find_by!(filename:, project:).filename).to eq(filename)
      end

      it 'links the asset to the project' do
        make_request
        expect(ScratchAsset.find_by!(filename:, project:).project_id).to eq(project.id)
      end

      it 'links the asset to the uploading user' do
        make_request
        expect(ScratchAsset.find_by!(filename:, project:).uploaded_user_id).to eq(teacher.id)
      end

      it 'attaches the uploaded file to the asset' do
        make_request
        expect(ScratchAsset.find_by!(filename:, project:).file).to be_attached
      end

      it 'stores the content of the file in the attachment' do
        make_request
        expect(ScratchAsset.find_by!(filename:, project:).file.download).to eq(upload)
      end

      it 'responds with 201 Created' do
        make_request
        expect(response).to have_http_status(:created)
      end

      it 'includes the status and filename (without extension) in the response' do
        make_request
        expect(response.parsed_body).to include(
          'status' => 'ok',
          'content-name' => basename
        )
      end

      context 'when the asset already exists in the same project' do
        let(:another_upload_path) { file_fixture('test_image_2.jpeg') }
        let(:upload) { File.binread(another_upload_path) }
        let(:original_upload) { File.binread(file_fixture(filename)) }

        before do
          create(:scratch_asset, :with_file, filename:, project:, asset_path: file_fixture(filename))
        end

        it 'does not update the content of the file in the attachment' do
          make_request
          expect(ScratchAsset.find_by!(filename:, project:).file.download).to eq(original_upload)
        end

        it 'responds with 201 Created' do
          make_request
          expect(response).to have_http_status(:created)
        end

        it 'includes the status and filename (without extension) in the response' do
          make_request
          expect(response.parsed_body).to include(
            'status' => 'ok',
            'content-name' => basename
          )
        end
      end

      it 'allows another user to upload the same filename to the same project' do
        make_request

        student = create(:student, school:)
        school_class = create(:school_class, school:, teacher_ids: [teacher.id])
        create(:class_student, school_class:, student_id: student.id)
        lesson = create(:lesson, school:, school_class:, user_id: teacher.id, visibility: 'students')
        project.update!(school:, lesson:)
        authenticated_in_hydra_as(student)

        expect do
          post '/api/scratch/assets/test_image_1.png',
               headers: request_headers,
               params: upload
        end.to change(ScratchAsset, :count).by(1)
        expect(
          ScratchAsset.where(filename:, project: project).pluck(:uploaded_user_id)
        ).to contain_exactly(student.id, teacher.id)
      end

      it 'remains idempotent when another request creates the same project asset first' do
        existing_asset = create_uploaded_scratch_asset(filename:, project:, body: 'winner-body')
        racing_asset = ScratchAsset.new(filename:, project:, uploaded_user_id: teacher.id)

        allow(ScratchAsset).to receive(:find_or_initialize_by).and_wrap_original do |original, *args|
          attributes = args.first
          if attributes[:filename] == filename &&
             attributes[:project]&.id == project.id &&
             attributes[:uploaded_user_id] == teacher.id
            racing_asset
          else
            original.call(*args)
          end
        end
        allow(racing_asset).to receive(:save!).and_raise(ActiveRecord::RecordNotUnique)

        blob_count = ActiveStorage::Blob.count

        expect { make_request }.not_to change(ScratchAsset, :count)

        expect(response).to have_http_status(:created)
        expect(existing_asset.reload.file.download).to eq('winner-body')
        expect(ActiveStorage::Blob.count).to eq(blob_count)
      end

      context 'when the current project can be viewed but not updated' do
        let(:student) { create(:student, school:) }
        let(:teacher_project) do
          school_class = create(:school_class, school:, teacher_ids: [teacher.id])
          create(:class_student, school_class:, student_id: student.id)
          lesson = create(:lesson, school:, school_class:, user_id: teacher.id, visibility: 'students')

          create_scratch_project(school:, lesson:, user_id: teacher.id)
        end
        let(:request_headers) do
          {
            'Authorization' => UserProfileMock::TOKEN,
            'Content-Type' => 'application/octet-stream',
            'Origin' => 'editor.com',
            'X-Project-ID' => teacher_project.identifier
          }
        end

        before do
          teacher_project
          authenticated_in_hydra_as(student)
        end

        it 'creates the asset on the original project for the current user without creating a remix' do
          expect { make_request }.not_to change(Project, :count)
          expect(ScratchAsset.count).to eq(1)

          uploaded_asset = ScratchAsset.find_by!(
            filename:,
            project: teacher_project,
            uploaded_user_id: student.id
          )
          expect(uploaded_asset.file.download).to eq(upload)
          expect(response).to have_http_status(:created)
        end

        it 'keeps the upload on the original project even when the student already has a remix' do
          remix = create_scratch_project(school:, user_id: student.id, remixed_from_id: teacher_project.id)

          expect { make_request }.to change(ScratchAsset, :count).by(1)

          expect(
            ScratchAsset.find_by!(filename:, project: teacher_project, uploaded_user_id: student.id).file.download
          ).to eq(upload)
          expect(ScratchAsset.find_by(project: remix, uploaded_user_id: student.id, filename:)).to be_nil
          expect(Project.where(remixed_from_id: teacher_project.id, user_id: student.id).count).to eq(1)
        end
      end
    end

    it 'responds 401 unauthorized when user is not signed in' do
      post '/api/scratch/assets/example.svg', headers: { 'X-Project-ID' => project.identifier }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'responds 404 Not Found when user is not part of a school' do
      user = create(:user)
      authenticated_in_hydra_as(user)

      post '/api/scratch/assets/example.svg', headers: project_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  def create_scratch_project(**attributes)
    create(:project, { project_type: Project::Types::CODE_EDITOR_SCRATCH, locale: nil }.merge(attributes)).tap do |scratch_project|
      create(:scratch_component, project: scratch_project)
    end
  end

  def create_uploaded_scratch_asset(filename:, project:, body:, uploaded_user_id: project&.user_id, content_type: 'image/png')
    ScratchAsset.create!(filename:, project:, uploaded_user_id:).tap do |asset|
      asset.file.attach(io: StringIO.new(body), filename:, content_type:)
    end
  end
end
