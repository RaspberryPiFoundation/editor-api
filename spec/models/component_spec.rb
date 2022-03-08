# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Component, type: :model do
  subject { build(:component) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:extension) }
  it { is_expected.to validate_presence_of(:index) }
  it { is_expected.to validate_uniqueness_of(:index).scoped_to(:project_id) }
end
