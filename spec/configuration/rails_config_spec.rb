# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Rails do
  it 'ensures the create_students_job queue only has one worker' do
    queues_config = described_class.application.config.good_job.queues
    # queues_config is a string like "create_students_job:1;default:5"

    # Parse the queues into a hash
    parsed_queues = queues_config.split(';').to_h do |q|
      name, concurrency = q.split(':')
      [name, concurrency.to_i]
    end

    expect(parsed_queues['create_students_job']).to eq(1)
  end
end
