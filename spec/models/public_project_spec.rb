# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicProject do
  subject(:public_project) { described_class.new(project) }

  let(:project) { build(:project, skip_identifier_generation: true, identifier: 'valid-identifier') }

  describe 'validation' do
    context 'when both project and public project are valid' do
      it { is_expected.to be_valid }

      it 'has no errors' do
        expect(public_project.errors).to be_empty
      end

      it 'persists project on save!' do
        public_project.save!
        expect(project).to be_persisted
      end
    end

    context 'when project is not valid' do
      before do
        project.locale = nil
        project.user_id = nil
      end

      it { is_expected.not_to be_valid }

      it 'has the project error' do
        public_project.valid?
        expect(public_project.errors.full_messages).to include("Locale can't be blank")
      end

      it 'raises validation error on save!' do
        expect do
          public_project.save!
        end.to raise_error(
          an_instance_of(ActiveModel::ValidationError)
            .and(having_attributes(message: "Validation failed: Locale can't be blank"))
        )
      end

      it 'does not persist project on save!' do
        public_project.save!
      rescue ActiveModel::ValidationError
        expect(project).not_to be_persisted
      end
    end

    context 'when public project is not valid' do
      before do
        project.identifier = 'InvalidIdentifier'
      end

      it { is_expected.not_to be_valid }

      it 'has the public project error' do
        public_project.valid?
        expect(public_project.errors.full_messages).to include('Identifier is invalid')
      end

      it 'raises validation error on save!' do
        expect do
          public_project.save!
        end.to raise_error(
          an_instance_of(ActiveModel::ValidationError)
            .and(having_attributes(message: 'Validation failed: Identifier is invalid'))
        )
      end

      it 'does not persist project on save!' do
        public_project.save!
      rescue ActiveModel::ValidationError
        expect(project).not_to be_persisted
      end
    end

    context 'when both project and public project are not valid' do
      before do
        project.locale = nil
        project.user_id = nil
        project.identifier = 'InvalidIdentifier'
      end

      it { is_expected.not_to be_valid }

      it 'has the project error' do
        public_project.valid?
        expect(public_project.errors.full_messages).to include("Locale can't be blank")
      end

      it 'has the public project error' do
        public_project.valid?
        expect(public_project.errors.full_messages).to include('Identifier is invalid')
      end

      it 'raises validation error including both errors on save!' do
        expect do
          public_project.save!
        end.to raise_error(
          an_instance_of(ActiveModel::ValidationError)
            .and(having_attributes(message: "Validation failed: Identifier is invalid, Locale can't be blank"))
        )
      end

      it 'does not persist project on save!' do
        public_project.save!
      rescue ActiveModel::ValidationError
        expect(project).not_to be_persisted
      end
    end
  end
end
