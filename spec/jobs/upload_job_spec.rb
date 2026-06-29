# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UploadJob do
  include ActiveJob::TestHelper

  around do |example|
    ClimateControl.modify GITHUB_AUTH_TOKEN: 'secret', GITHUB_WEBHOOK_REF: 'branches/whatever' do
      example.run
    end
  end

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
                      name: 'index.html',
                      extension: '.html',
                      object: {
                        __typename: 'Blob',
                        text: '<h1>Hello world!</h1>',
                        isBinary: false
                      }
                    },
                    {
                      name: 'styles.css',
                      extension: '.css',
                      object: {
                        __typename: 'Blob',
                        text: ".h1 {\n  color: red;\n}\n",
                        isBinary: false
                      }
                    },
                    {
                      name: 'script.js',
                      extension: '.js',
                      object: {
                        __typename: 'Blob',
                        text: "console.log('Hello, world!')",
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
      type: Project::Types::PYTHON,
      locale: 'ja-JP',
      components: [
        {
          name: 'main',
          extension: 'py',
          content: "#!/bin/python3\n\nfrom p5 import *\nfrom random import randint, seed\n\n# Include global variables here\n\n\ndef setup():\n# Put code to run once here\n\n\ndef draw():\n# Put code to run every frame here\n\n  \n# Keep this to run your code\nrun()\n",
          default: true
        },
        {
          name: 'index',
          extension: 'html',
          content: '<h1>Hello world!</h1>',
          default: false
        },
        {
          name: 'styles',
          extension: 'css',
          content: ".h1 {\n  color: red;\n}\n",
          default: false
        },
        {
          name: 'script',
          extension: 'js',
          content: "console.log('Hello, world!')",
          default: false
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
      audio: [
        {
          filename: 'music.mp3',
          io: instance_of(StringIO)
        }
      ]
    }
  end

  context 'with the build flag undefined' do
    let(:raw_response) { modifiable_response }

    before do
      allow(GithubApi::Client).to receive(:query).and_return(graphql_response)
      allow(ProjectImporter).to receive(:new).and_call_original

      stub_request(:get, 'https://github.com/me/my-amazing-repo/raw/branches/whatever/ja-JP/code/dont-collide-starter/astronaut1.png').to_return(status: 200, body: '', headers: {})
      stub_request(:get, 'https://github.com/me/my-amazing-repo/raw/branches/whatever/ja-JP/code/dont-collide-starter/music.mp3').to_return(status: 200, body: '', headers: {})
      stub_request(:get, 'https://github.com/me/my-amazing-repo/raw/branches/whatever/ja-JP/code/dont-collide-starter/video.mp4').to_return(status: 200, body: '', headers: {})
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
      stub_request(:get, 'https://github.com/me/my-amazing-repo/raw/branches/whatever/ja-JP/code/dont-collide-starter/astronaut1.png').to_return(status: 200, body: '', headers: {})
      stub_request(:get, 'https://github.com/me/my-amazing-repo/raw/branches/whatever/ja-JP/code/dont-collide-starter/music.mp3').to_return(status: 200, body: '', headers: {})
      stub_request(:get, 'https://github.com/me/my-amazing-repo/raw/branches/whatever/ja-JP/code/dont-collide-starter/video.mp4').to_return(status: 200, body: '', headers: {})

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

  context 'with multiple projects where an earlier one has build set to false' do
    let(:raw_response) { modifiable_response.deep_dup }

    before do
      entries = raw_response['data']['repository']['object']['entries']

      # Turn the existing project into a build: false project
      build_false_dir = entries.find { |entry| entry['name'] == 'dont-collide-starter' }
      build_false_config = build_false_dir['object']['entries'].find { |entry| entry['name'] == 'project_config.yml' }
      build_false_config['object']['text'] += "build: false\n"

      # add second project with build set to true
      entries << {
        'name' => 'build-me-starter',
        'object' => {
          '__typename' => 'Tree',
          'entries' => [
            {
              'name' => 'main.py',
              'extension' => '.py',
              'object' => {
                '__typename' => 'Blob',
                'text' => "print('hello')\n",
                'isBinary' => false
              }
            },
            {
              'name' => 'project_config.yml',
              'extension' => '.yml',
              'object' => {
                '__typename' => 'Blob',
                'text' => "name: \"Build Me\"\nidentifier: \"build-me-starter\"\ntype: \"python\"\nbuild: true\n",
                'isBinary' => true
              }
            }
          ]
        }
      }

      allow(GithubApi::Client).to receive(:query).and_return(graphql_response)
      allow(ProjectImporter).to receive(:new).and_call_original
    end

    it 'still imports the later buildable project' do
      expect { described_class.perform_now(payload) }.to change(Project, :count).by(1)
      expect(Project.find_by(identifier: 'build-me-starter', locale: 'ja-JP')).to be_present
    end

    it 'does not import the build: false project' do
      described_class.perform_now(payload)
      expect(Project.find_by(identifier: 'dont-collide-starter', locale: 'ja-JP')).to be_nil
    end
  end

  context 'when GitHub returns nothing for the locale' do
    let(:raw_response) { { data: { repository: nil } } }

    before do
      allow(GithubApi::Client).to receive(:query).and_return(graphql_response)
    end

    it 'raises DataNotFoundError' do
      expect do
        described_class.perform_now(payload)
      end.to raise_error(UploadJob::DataNotFoundError)
    end
  end

  context 'when a scratch project is uploaded' do
    let(:scratch_payload) do
      {
        repository: { name: 'my-amazing-repo', owner: { name: 'me' } },
        commits: [{ added: ['ja-JP/code/scratch-integration-test-starter/main.sb3'], modified: [], removed: [] }]
      }
    end
    let(:scratch_project_json) do
      {
        targets: [
          {
            costumes: [{ md5ext: 'test_image_1.png' }],
            sounds: [{ md5ext: 'test_audio_1.mp3' }]
          }
        ]
      }
    end
    let(:scratch_sb3_body) do
      sb3_archive_string(
        'project.json' => scratch_project_json.to_json,
        'test_image_1.png' => sb3_fixture_content('test_image_1.png'),
        'test_audio_1.mp3' => sb3_fixture_content('test_audio_1.mp3')
      )
    end
    let(:raw_response) do
      {
        data: {
          repository: {
            object: {
              __typename: 'Tree',
              entries: [
                {
                  name: 'scratch-integration-test-starter',
                  object: {
                    __typename: 'Tree',
                    entries: [
                      {
                        name: 'main.sb3',
                        extension: '.sb3',
                        object: {
                          __typename: 'Blob',
                          text: nil,
                          isBinary: true
                        }
                      },
                      {
                        name: 'project_config.yml',
                        extension: '.yml',
                        object: {
                          __typename: 'Blob',
                          text: "name: \"Scratch Integration Test\"\nidentifier: \"scratch-integration-test-starter\"\ntype: \"code_editor_scratch\"\n",
                          isBinary: false
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

    before do
      allow(GithubApi::Client).to receive(:query).and_return(graphql_response)
      allow(ProjectImporter).to receive(:new).and_call_original

      stub_request(:get, 'https://github.com/me/my-amazing-repo/raw/branches/whatever/ja-JP/code/scratch-integration-test-starter/main.sb3')
        .to_return(status: 200, body: scratch_sb3_body, headers: {})
    end

    it 'imports the Scratch project with the sb3 component as io' do
      described_class.perform_now(scratch_payload)

      expect(ProjectImporter).to have_received(:new).with(
        hash_including(
          name: 'Scratch Integration Test',
          identifier: 'scratch-integration-test-starter',
          type: Project::Types::CODE_EDITOR_SCRATCH,
          locale: 'ja-JP',
          images: [],
          videos: [],
          audio: [],
          components: [
            hash_including(
              name: 'main',
              extension: 'sb3',
              io: an_object_responding_to(:read)
            )
          ]
        )
      )
    end

    it 'requests the sb3 file from the correct URL' do
      described_class.perform_now(scratch_payload)

      expect(WebMock).to have_requested(:get, 'https://github.com/me/my-amazing-repo/raw/branches/whatever/ja-JP/code/scratch-integration-test-starter/main.sb3').once
    end

    it 'saves the Scratch project to the database' do
      expect { described_class.perform_now(scratch_payload) }.to change(Project, :count).by(1)

      project = Project.find_by(identifier: 'scratch-integration-test-starter', locale: 'ja-JP')
      expect(project.project_type).to eq(Project::Types::CODE_EDITOR_SCRATCH)
      expect(project.scratch_component.content).to eq(JSON.parse(scratch_project_json.to_json))
    end
  end

  context 'when locale is unsupported' do
    let(:raw_response) { { data: { repository: nil } } }
    let(:bad_payload) do
      { repository: { name: 'my-amazing-repo', owner: { name: 'me' } }, commits: [{ added: ['unsupported-locale/code/dont-collide-starter/main.py'], modified: [], removed: [] }] }
    end

    before do
      allow(GithubApi::Client).to receive(:query).and_return(graphql_response)
    end

    it 'does not request data from Github' do
      described_class.perform_now(bad_payload)
      expect(GithubApi::Client).not_to have_received(:query)
    end
  end
end
