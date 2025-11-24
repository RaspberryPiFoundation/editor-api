# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolStudent::CreateBatchSSO, type: :unit do
  let(:school) { create(:verified_school) }
  let(:current_user) { create(:teacher, school:) }

  let(:school_students_params) do
    [
      {
        name: 'Test Student 1',
        email: 'student1@example.com'
      },
      {
        name: 'Test Student 2',
        email: 'student2@example.com'
      }
    ]
  end

  context 'when SSO creation succeeds' do
    let(:user_ids) { [SecureRandom.uuid, SecureRandom.uuid] }

    before do
      # Force memoization of user_ids before stub so they're consistent
      user_ids
      stub_profile_api_create_school_students_sso(user_ids:)
    end

    it 'returns a successful operation response' do
      response = described_class.call(school:, school_students_params:, current_user:)
      expect(response.success?).to be(true)
    end

    it 'makes a profile API call with correct parameters' do
      described_class.call(school:, school_students_params:, current_user:)

      # TODO: Replace with WebMock assertion once the profile API has been built.
      expect(ProfileApiClient).to have_received(:create_school_students_sso)
        .with(token: current_user.token, students: school_students_params, school_id: school.id)
    end

    it 'transforms nil values to empty strings before API call' do
      params_with_nils = [
        { name: 'Test Student 1', email: nil },
        { name: nil, email: 'student2@example.com' }
      ]
      expected_params = [
        { name: 'Test Student 1', email: '' },
        { name: '', email: 'student2@example.com' }
      ]

      described_class.call(school:, school_students_params: params_with_nils, current_user:)

      expect(ProfileApiClient).to have_received(:create_school_students_sso)
        .with(token: current_user.token, students: expected_params, school_id: school.id)
    end

    it 'creates roles associating students with the school' do
      described_class.call(school:, school_students_params:, current_user:)

      user_ids.each do |user_id|
        expect(Role.student.where(school:, user_id:)).to exist
      end
    end

    it 'returns the student data from Profile API' do
      response = described_class.call(school:, school_students_params:, current_user:)
      students = response[:school_students]

      expect(students.length).to eq(2)

      # Verify first student item (hash with :student and metadata)
      first_student_item = students[0]
      expect(first_student_item[:student]).to be_a(User)
      expect(first_student_item[:student].id).to eq(user_ids[0])
      expect(first_student_item[:student].name).to eq('SSO Test Student 1')
      expect(first_student_item[:success]).to be(true)

      # Verify second student item
      second_student_item = students[1]
      expect(second_student_item[:student]).to be_a(User)
      expect(second_student_item[:student].id).to eq(user_ids[1])
      expect(second_student_item[:student].name).to eq('SSO Test Student 2')
      expect(second_student_item[:success]).to be(true)
    end

    context 'when roles already exist for some students' do
      let(:user_ids) { [SecureRandom.uuid, SecureRandom.uuid] }

      before do
        # Pre-create a role for the first student
        Role.create!(role: :student, school_id: school.id, user_id: user_ids[0])
      end

      it 'does not duplicate existing roles' do
        roles_before_call = Role.student.where(school_id: school.id).to_a

        described_class.call(school:, school_students_params:, current_user:)

        roles_after_call = Role.student.where(school_id: school.id).to_a
        new_student_roles = roles_after_call - roles_before_call

        # Should only create 1 new student role (for second student) since first already exists
        expect(new_student_roles.length).to eq(1)
        expect(new_student_roles.first.user_id).to eq(user_ids[1])
      end

      it 'does not raise an error' do
        expect do
          described_class.call(school:, school_students_params:, current_user:)
        end.not_to raise_error
      end

      it 'still returns all students in the response' do
        response = described_class.call(school:, school_students_params:, current_user:)
        expect(response[:school_students].length).to eq(2)
      end
    end
  end

  context 'when validation errors occur' do
    before do
      stub_profile_api_create_school_students_sso_validation_error
    end

    it 'returns a failed operation response' do
      response = described_class.call(school:, school_students_params:, current_user:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school:, school_students_params:, current_user:)
      expect(response[:error]).to eq("Error creating one or more students - see 'errors' key for details")
    end

    it 'returns the error type as validation_error' do
      response = described_class.call(school:, school_students_params:, current_user:)
      expect(response[:error_type]).to eq(:validation_error)
    end

    it 'returns formatted validation errors' do
      response = described_class.call(school:, school_students_params:, current_user:)
      expect(response[:errors]).to eq({
                                        '0.name' => 'minLength.openapi.requestValidation',
                                        '0.email' => 'minLength.openapi.requestValidation'
                                      })
    end

    it 'does not create any student roles when validation fails' do
      initial_student_role_count = Role.student.count

      described_class.call(school:, school_students_params:, current_user:)

      expect(Role.student.count).to eq(initial_student_role_count)
    end
  end

  context 'when a standard error occurs' do
    before do
      allow(ProfileApiClient).to receive(:create_school_students_sso)
        .and_raise(StandardError.new('Network timeout'))
      allow(Sentry).to receive(:capture_exception)
    end

    it 'returns a failed operation response' do
      response = described_class.call(school:, school_students_params:, current_user:)
      expect(response.failure?).to be(true)
    end

    it 'returns the error message in the operation response' do
      response = described_class.call(school:, school_students_params:, current_user:)
      expect(response[:error]).to eq('Error importing the class or creating students: Network timeout')
    end

    it 'returns the error type as standard_error' do
      response = described_class.call(school:, school_students_params:, current_user:)
      expect(response[:error_type]).to eq(:standard_error)
    end

    it 'does not include an errors field for standard errors' do
      response = described_class.call(school:, school_students_params:, current_user:)
      expect(response).not_to have_key(:errors)
    end

    it 'sends the exception to Sentry' do
      described_class.call(school:, school_students_params:, current_user:)
      expect(Sentry).to have_received(:capture_exception).with(kind_of(StandardError))
    end

    it 'does not create any student roles when standard error occurs' do
      initial_student_role_count = Role.student.count

      described_class.call(school:, school_students_params:, current_user:)

      expect(Role.student.count).to eq(initial_student_role_count)
    end
  end
end
