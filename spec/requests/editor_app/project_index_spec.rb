# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Code Editor project index' do
  around do |example|
    ClimateControl.modify(
      EDITOR_APP_HOSTS: 'editor.example.com',
      EDITOR_PUBLIC_URL: 'https://classroom.example.com'
    ) { example.run }
  end

  let(:user) { create(:user) }
  let(:index_url) { 'http://editor.example.com/en/projects' }

  describe 'GET #index' do
    before { stub_sign_in(user) }

    it 'lists their own projects, most recently edited first' do
      create(:project, user_id: user.id, locale: nil, name: 'Older', updated_at: 2.days.ago)
      create(:project, user_id: user.id, locale: nil, name: 'Newer', updated_at: 1.hour.ago)
      get index_url
      expect(response.body.index('Newer')).to be < response.body.index('Older')
    end

    it 'says when a project was last edited' do
      create(:project, user_id: user.id, locale: nil, updated_at: 2.hours.ago)
      get index_url
      expect(response.body).to include('Edited about 2 hours ago')
    end

    it 'links to each project and offers renaming and deleting it' do
      project = create(:project, user_id: user.id, locale: nil)
      get index_url
      expect(response.body).to include("/en/projects/#{project.identifier}")
        .and include("rename-project-#{project.identifier}")
        .and include("delete-project-#{project.identifier}")
    end

    it 'leaves out school projects, which belong to Code Classroom' do
      school = create(:school)
      teacher = create(:teacher, school:)
      stub_sign_in(teacher)
      create(:project, user_id: teacher.id, school:, locale: nil, name: 'School work')
      create(:project, user_id: teacher.id, locale: nil, name: 'My own')
      get index_url
      expect(response.body).to include('My own').and not_include('School work')
    end

    it "leaves out other people's projects" do
      create(:project, locale: nil, name: 'Not mine')
      get index_url
      expect(response.body).not_to include('Not mine')
    end

    it 'says so when there is nothing to list' do
      get index_url
      expect(response.body).to include('No projects created yet')
    end

    it 'offers the next page once there are more projects than fit on one' do
      create_list(:project, EditorApp::ProjectsController::PAGE_SIZE + 1, user_id: user.id, locale: nil)
      get index_url
      expect(response.body).to include('Load more projects').and include('/en/projects?page=2')
    end

    it 'does not offer a next page when everything fits' do
      create_list(:project, 2, user_id: user.id, locale: nil)
      get index_url
      expect(response.body).not_to include('Load more projects')
    end

    it 'offers the two project types the React create modal offered outside a lesson' do
      get index_url
      expect(response.body).to include('value="python"')
        .and include('value="html"')
        .and not_include('value="code_editor_scratch"')
    end
  end

  it 'sends anybody not signed in to the home page, which offers the login' do
    get index_url
    expect(response).to redirect_to('/en')
  end

  context 'when a school student is signed in' do
    before { stub_sign_in(create(:student, school: create(:school))) }

    it 'refuses them, because their projects live in Code Classroom' do
      get index_url
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST #create' do
    before { stub_sign_in(user) }

    it 'creates a Python project with an empty main.py and opens it' do
      post index_url, params: { project: { name: 'My project', project_type: 'python' } }
      project = Project.find_by(name: 'My project')
      expect(project.components.map { |c| [c.name, c.extension, c.content, c.default] })
        .to eq([['main', 'py', '', true]])
      expect(response).to redirect_to("/en/projects/#{project.identifier}")
    end

    it 'creates a web project with an empty index.html and style.css' do
      post index_url, params: { project: { name: 'My site', project_type: 'html' } }
      expect(Project.find_by(name: 'My site').components.map(&:name)).to contain_exactly('index', 'style')
    end

    it 'rejects a project type it has no starter content for' do
      post index_url, params: { project: { name: 'Blocks', project_type: 'code_editor_scratch' } }
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'PATCH #update' do
    before { stub_sign_in(user) }

    let(:project) { create(:project, user_id: user.id, locale: nil, name: 'Before') }

    it 'renames their project and says so' do
      patch "http://editor.example.com/en/projects/#{project.identifier}", params: { project: { name: 'After' } }
      expect(project.reload.name).to eq('After')
      expect(response).to redirect_to('/en/projects')
      follow_redirect!
      expect(response.body).to include('Project renamed')
    end

    it "refuses to rename somebody else's project" do
      other = create(:project, locale: nil)
      patch "http://editor.example.com/en/projects/#{other.identifier}", params: { project: { name: 'Mine now' } }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'DELETE #destroy' do
    before { stub_sign_in(user) }

    let(:project) { create(:project, user_id: user.id, locale: nil) }

    it 'deletes their project and says so' do
      delete "http://editor.example.com/en/projects/#{project.identifier}"
      expect(Project.exists?(project.id)).to be(false)
      follow_redirect!
      expect(response.body).to include('Project deleted')
    end
  end
end
