# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lesson do
  before do
    stub_user_info_api
  end

  describe 'associations' do
    it 'optionally belongs to a school class' do
      lesson = create(:lesson, school_class: build(:school_class))
      expect(lesson.school_class).to be_a(SchoolClass)
    end
  end

  describe 'validations' do
    subject(:lesson) { build(:lesson) }

    it 'has a valid default factory' do
      expect(lesson).to be_valid
    end

    it 'can save the default factory' do
      expect { lesson.save! }.not_to raise_error
    end

    it 'requires a user_id' do
      lesson.user_id = ' '
      expect(lesson).to be_invalid
    end

    it 'requires a UUID user_id' do
      lesson.user_id = 'invalid'
      expect(lesson).to be_invalid
    end

    it 'requires a name' do
      lesson.name = ' '
      expect(lesson).to be_invalid
    end

    it 'requires a visibility' do
      lesson.visibility = ' '
      expect(lesson).to be_invalid
    end

    it "requires a visibility that is either 'private', 'school' or 'public'" do
      lesson.visibility = 'invalid'
      expect(lesson).to be_invalid
    end
  end
end
