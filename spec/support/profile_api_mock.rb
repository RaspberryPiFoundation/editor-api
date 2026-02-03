# frozen_string_literal: true

module ProfileApiMock
  # TODO: Replace with WebMock HTTP stubs once the profile API has been built.

  def stub_profile_api_list_school_students(school:, student_attributes:)
    now = Time.current.to_fs(:iso8601) # rubocop:disable Naming/VariableNumber

    # Simulate raw API responses with camelCase, then use build_student for conversion
    raw_responses = student_attributes.map do |student_attrs|
      {
        schoolId: school.id,
        id: student_attrs[:id],
        username: student_attrs[:username],
        name: student_attrs[:name],
        email: student_attrs[:email],
        ssoProviders: student_attrs[:ssoProviders] || [], # API returns camelCase
        createdAt: now,
        updatedAt: now,
        discardedAt: nil
      }
    end

    students = raw_responses.map { |attrs| ProfileApiClient.send(:build_student, attrs) }

    allow(ProfileApiClient).to receive(:list_school_students).and_return(students)
  end

  def stub_profile_api_create_school_student(user_id: SecureRandom.uuid)
    allow(ProfileApiClient).to receive(:create_school_student).and_return(created: [user_id])
  end

  def stub_profile_api_create_school(id: SecureRandom.uuid, code: '99-12-34')
    now = Time.current.to_fs(:iso8601) # rubocop:disable Naming/VariableNumber
    allow(ProfileApiClient).to receive(:create_school).and_return(
      ProfileApiClient::School.new(
        id:,
        schoolCode: code,
        updatedAt: now,
        createdAt: now,
        discardedAt: nil
      )
    )
  end

  def stub_profile_api_create_school_students(user_ids: [SecureRandom.uuid])
    allow(ProfileApiClient).to receive(:create_school_students).and_return(created: [user_ids.join(', ')])
  end

  def stub_profile_api_create_school_students_validation_error
    # 13/11/24: Response from profile from this request:
    # {
    #   "school_students": [
    #     {
    #       "username": "student-to-create",
    #       "password": "Password",
    #       "name": ""
    #     },
    #     {
    #       "username": "student-to-create",
    #       "password": "Student2024",
    #       "name": "Password"
    #     },
    #     {
    #       "username": "another-student-to-create-2",
    #       "password": "Pass",
    #       "name": ""
    #     }
    #   ]
    # }
    allow(ProfileApiClient).to receive(:create_school_students).and_raise(
      ProfileApiClient::Student422Error.new(
        [{ 'path' => '0.username', 'errorCode' => 'isUniqueInBatch', 'message' => 'Username must be unique in the batch data', 'location' => 'body', 'username' => 'student-to-create' },
         { 'path' => '0.password', 'errorCode' => 'isComplex', 'message' => 'Password is too simple (it should not be easily guessable, <a href="https://my.raspberrypi.org/password-help">need password help?</a>)', 'location' => 'body', 'username' => 'student-to-create' },
         { 'path' => '0.name', 'errorCode' => 'notEmpty', 'message' => 'Validation notEmpty on name failed', 'location' => 'body', 'username' => 'student-to-create' },
         { 'path' => '1.username', 'errorCode' => 'isUniqueInBatch', 'message' => 'Username must be unique in the batch data', 'location' => 'body', 'username' => 'student-to-create' },
         { 'path' => '2.password', 'errorCode' => 'minLength', 'message' => 'Password must be at least 8 characters', 'location' => 'body', 'username' => 'another-student-to-create-2' },
         { 'path' => '2.name', 'errorCode' => 'notEmpty', 'message' => 'Validation notEmpty on name failed', 'location' => 'body', 'username' => 'another-student-to-create-2' }]
      )
    )
  end

  def stub_profile_api_update_school_student
    allow(ProfileApiClient).to receive(:update_school_student)

    student = build(:profile_api_client_student)
    allow(ProfileApiClient).to receive(:list_school_students).and_return([student])
  end

  def stub_profile_api_school_student(sso: false)
    student = sso ? build(:profile_api_client_student, :sso) : build(:profile_api_client_student)

    # Update service now uses list_school_students instead of school_student
    allow(ProfileApiClient).to receive_messages(
      list_school_students: [student],
      school_student: student
    )
  end

  def stub_profile_api_delete_school_student
    allow(ProfileApiClient).to receive(:delete_school_student)
  end

  def stub_profile_api_create_safeguarding_flag
    allow(ProfileApiClient).to receive(:create_safeguarding_flag)
  end

  def stub_profile_api_create_school_students_sso(user_ids: [SecureRandom.uuid])
    responses = user_ids.map.with_index do |user_id, index|
      student = build(:profile_api_client_student, :sso, id: user_id, name: "SSO Test Student #{index + 1}")
      { id: student.id, name: student.name, success: true }
    end
    allow(ProfileApiClient).to receive(:create_school_students_sso).and_return(responses)
  end

  def stub_profile_api_create_school_students_sso_validation_error
    allow(ProfileApiClient).to receive(:create_school_students_sso).and_raise(
      ProfileApiClient::Student422Error.new(
        [{ 'path' => '0.name', 'errorCode' => 'minLength.openapi.requestValidation', 'message' => 'must NOT have fewer than 1 characters', 'location' => 'body' },
         { 'path' => '0.email', 'errorCode' => 'minLength.openapi.requestValidation', 'message' => 'must NOT have fewer than 3 characters', 'location' => 'body' }]
      )
    )
  end

  def stub_profile_api_validate_school_students
    allow(ProfileApiClient).to receive(:validate_school_students)
  end

  def stub_profile_api_validate_students_with_validation_error
    allow(ProfileApiClient).to receive(:validate_school_students).and_raise(
      ProfileApiClient::Student422Error.new(
        [{ 'path' => '0.username', 'errorCode' => 'isUniqueInBatch', 'message' => 'Username must be unique in the batch data', 'location' => 'body', 'username' => 'student-to-create' },
         { 'path' => '0.password', 'errorCode' => 'isComplex', 'message' => 'Password is too simple (it should not be easily guessable, <a href="https://my.raspberrypi.org/password-help">need password help?</a>)', 'location' => 'body', 'username' => 'student-to-create' },
         { 'path' => '0.name', 'errorCode' => 'notEmpty', 'message' => 'Validation notEmpty on name failed', 'location' => 'body', 'username' => 'student-to-create' },
         { 'path' => '1.username', 'errorCode' => 'isUniqueInBatch', 'message' => 'Username must be unique in the batch data', 'location' => 'body', 'username' => 'student-to-create' },
         { 'path' => '2.password', 'errorCode' => 'minLength', 'message' => 'Password must be at least 8 characters', 'location' => 'body', 'username' => 'another-student-to-create-2' },
         { 'path' => '2.name', 'errorCode' => 'notEmpty', 'message' => 'Validation notEmpty on name failed', 'location' => 'body', 'username' => 'another-student-to-create-2' }]
      )
    )
  end
end
