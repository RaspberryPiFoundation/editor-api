# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lesson::Archive, type: :unit do
  before do
    stub_user_info_api
  end

  let(:lesson) { create(:lesson) }

  it 'returns a successful operation response' do
    response = described_class.call(lesson:)
    expect(response.success?).to be(true)
  end

  it 'archives the lesson' do
    described_class.call(lesson:)
    expect(lesson.reload.archived?).to be(true)
  end
end
