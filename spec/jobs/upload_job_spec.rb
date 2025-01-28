# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UploadJob do
  around do |example|
    ClimateControl.modify GITHUB_AUTH_TOKEN: 'secret', GITHUB_WEBHOOK_REF: 'branches/whatever' do
      example.run
    end
  end

  ActiveJob::Base.queue_adapter = :test
  let(:graphql_response) do
    GraphQL::Client::Response.new(raw_response, data: UploadJob::ProjectContentQuery.new(raw_response['data'], GraphQL::Client::Errors.new))
  end
  let(:payload) do
    { repository: { name: 'my-amazing-repo', owner: { name: 'me' } }, commits: [{ added: ['ja-JP/code/dont-collide-starter/main.py'], modified: [], removed: [] }] }
  end
  let(:variables) do
    { repository: 'my-amazing-repo', owner: 'me', expression: "#{ENV.fetch('GITHUB_WEBHOOK_REF')}:ja-JP/code" }
  end

  let(:modifiable_response) do
    {
      data: {
        repository: {
          object: {
            __typename: 'Tree',
            entries: [
              {
                name: 'dont-collide-starter',
                object: {
                  __typename: 'Tree',
                  entries: [
                    {
                      name: 'astronaut1.png',
                      extension: '.png',
                      object: {
                        __typename: 'Blob',
                        text: nil,
                        isBinary: true
                      }
                    },
                    {
                      name: 'music.mp3',
                      extension: '.mp3',
                      object: {
                        __typename: 'Blob',
                        text: nil,
                        isBinary: true
                      }
                    },
                    {
                      name: 'video.mp4',
                      extension: '.mp4',
                      object: {
                        __typename: 'Blob',
                        text: nil,
                        isBinary: true
                      }
                    },
                    {
                      name: 'main.py',
                      extension: '.py',
                      object: {
                        __typename: 'Blob',
                        text: "#!/bin/python3\n\nfrom p5 import *\nfrom random import randint, seed\n\n# Include global variables here\n\n\ndef setup():\n# Put code to run once here\n\n\ndef draw():\n# Put code to run every frame here\n\n  \n# Keep this to run your code\nrun()\n",
                        isBinary: false
                      }
                    },
                    {
                      name: 'project_config.yml',
                      extension: '.yml',
                      object: {
                        __typename: 'Blob',
                        text: "name: \"Don't Collide!\"\nidentifier: \"dont-collide-starter\"\ntype: \"python\"\n",
                        isBinary: true
                      }
                    }
                  ]
                }
              }
            ]
          }
        }
      }
    }.deep_stringify_keys
  end

  let(:project_importer_params) do
    {
      name: "Don't Collide!",
      identifier: 'dont-collide-starter',
      type: 'python',
      locale: 'ja-JP',
      components: [
        {
          name: 'main',
          extension: 'py',
          content: "#!/bin/python3\n\nfrom p5 import *\nfrom random import randint, seed\n\n# Include global variables here\n\n\ndef setup():\n# Put code to run once here\n\n\ndef draw():\n# Put code to run every frame here\n\n  \n# Keep this to run your code\nrun()\n",
          default: true
        }
      ],
      images: [
        {
          filename: 'astronaut1.png',
          io: instance_of(StringIO)
        }
      ],
      videos: [
        {
          filename: 'video.mp4',
          io: instance_of(StringIO)
        }
      ],
      audio_files: [
        {
          filename: 'music.mp3',
          io: instance_of(StringIO)
        }
      ]
    }
  end

  before do
    stub_request(:get, 'https://github.com/me/my-amazing-repo/raw/branches/whatever/ja-JP/code/dont-collide-starter/astronaut1.png').to_return(status: 200, body: '', headers: {})
    stub_request(:get, 'https://github.com/me/my-amazing-repo/raw/branches/whatever/ja-JP/code/dont-collide-starter/music.mp3').to_return(status: 200, body: '', headers: {})
    stub_request(:get, 'https://github.com/me/my-amazing-repo/raw/branches/whatever/ja-JP/code/dont-collide-starter/video.mp4').to_return(status: 200, body: '', headers: {})
  end

  context 'with the build flag undefined' do
    let(:raw_response) { modifiable_response }

    before do
      allow(GithubApi::Client).to receive(:query).and_return(graphql_response)
      allow(ProjectImporter).to receive(:new).and_call_original
    end

    it 'enqueues the job' do
      expect { described_class.perform_later(payload) }.to enqueue_job
    end

    it 'requests data from Github' do
      described_class.perform_now(payload)
      expect(GithubApi::Client).to have_received(:query).with(UploadJob::ProjectContentQuery, variables:)
    end

    it 'imports the project in the correct format' do
      described_class.perform_now(payload)
      expect(ProjectImporter).to have_received(:new)
        .with(**project_importer_params)
    end

    it 'requests the image from the correct URL' do
      described_class.perform_now(payload)
      expect(WebMock).to have_requested(:get, 'https://github.com/me/my-amazing-repo/raw/branches/whatever/ja-JP/code/dont-collide-starter/astronaut1.png').once
    end

    it 'saves the project to the database' do
      expect { described_class.perform_now(payload) }.to change(Project, :count).by(1)
    end
  end

  context 'with the build flag set to false' do
    let(:raw_response) { modifiable_response.deep_dup }

    before do
      project_dir_entry = raw_response['data']['repository']['object']['entries'].find do |entry|
        entry['name'] == 'dont-collide-starter'
      end

      project_config_entry = project_dir_entry['object']['entries'].find do |entry|
        entry['name'] == 'project_config.yml'
      end

      project_config_entry['object']['text'] += "build: false\n"

      allow(GithubApi::Client).to receive(:query).and_return(graphql_response)
      allow(ProjectImporter).to receive(:new).and_call_original
    end

    it 'does not save the project to the database' do
      expect { described_class.perform_now(payload) }.not_to change(Project, :count)
    end
  end

  context 'with the build flag set to true' do
    let(:raw_response) { modifiable_response.deep_dup }

    before do
      project_dir_entry = raw_response['data']['repository']['object']['entries'].find do |entry|
        entry['name'] == 'dont-collide-starter'
      end

      project_config_entry = project_dir_entry['object']['entries'].find do |entry|
        entry['name'] == 'project_config.yml'
      end

      project_config_entry['object']['text'] += "build: true\n"

      allow(GithubApi::Client).to receive(:query).and_return(graphql_response)
      allow(ProjectImporter).to receive(:new).and_call_original
    end

    it 'saves the project to the database' do
      expect { described_class.perform_now(payload) }.to change(Project, :count).by(1)
    end
  end
end
