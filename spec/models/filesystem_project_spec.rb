# frozen_string_literal: true

require 'rails_helper'

describe FilesystemProject do
  before do
    PhraseIdentifier.seed!
  end

  it 'imports all starter projects' do
    expect { described_class.import_all! }.not_to raise_error
  end
end
