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
    { repository: { name: 'my-amazing-repo', owner: { name: 'me' } } }
  end
  let(:variables) do
    { repository: 'my-amazing-repo', owner: 'me', expression: "#{ENV.fetch('GITHUB_WEBHOOK_REF')}:en/code" }
  end

  let(:raw_response) do
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
      ]
    }
  end

  before do
    allow(GitHub::Client).to receive(:query).and_return(graphql_response)
    stub_request(:get, 'https://github.com/me/my-amazing-repo/raw/branches/whatever/en/code/dont-collide-starter/astronaut1.png').to_return(status: 200, body: '', headers: {})
    allow(ProjectImporter).to receive(:new).and_call_original
  end

  it 'enqueues the job' do
    expect { described_class.perform_later(payload) }.to enqueue_job
  end

  it 'requests data from GitHub' do
    described_class.perform_now(payload)
    expect(GitHub::Client).to have_received(:query).with(UploadJob::ProjectContentQuery, variables:)
  end

  it 'imports the project in the correct format' do
    described_class.perform_now(payload)
    expect(ProjectImporter).to have_received(:new)
      .with(**project_importer_params)
  end

  it 'requests the image from the correct URL' do
    described_class.perform_now(payload)
    expect(WebMock).to have_requested(:get, 'https://github.com/me/my-amazing-repo/raw/branches/whatever/en/code/dont-collide-starter/astronaut1.png').once
  end

  it 'saves the project to the database' do
    expect { described_class.perform_now(payload) }.to change(Project, :count).by(1)
  end
end
