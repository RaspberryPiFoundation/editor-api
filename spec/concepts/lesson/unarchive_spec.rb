# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lesson::Unarchive, type: :unit do
  before do
    stub_user_info_api
  end

  let(:lesson) { create(:lesson, archived_at: Time.now.utc) }

  it 'returns a successful operation response' do
    response = described_class.call(lesson:)
    expect(response.success?).to be(true)
  end

  it 'unarchives the lesson' do
    described_class.call(lesson:)
    expect(lesson.reload.archived?).to be(false)
  end
end
