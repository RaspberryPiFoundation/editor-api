# frozen_string_literal: true

require 'rails_helper'

describe FilesystemProject do
  it 'imports all starter projects' do
    expect { described_class.import_all! }.not_to raise_error
  end
end
