# frozen_string_literal: true

module ProfileApiMock
  # TODO: Replace with WebMock HTTP stubs once the profile API has been built.

  def stub_profile_api_remove_school_owner
    allow(ProfileApiClient).to receive(:remove_school_owner)
  end

  def stub_profile_api_remove_school_teacher
    allow(ProfileApiClient).to receive(:remove_school_teacher)
  end

  def stub_profile_api_list_school_students(school:, student_attributes:)
    now = Time.current.to_fs(:iso8601) # rubocop:disable Naming/VariableNumber

    students = student_attributes.map do |student_attrs|
      ProfileApiClient::Student.new(
        schoolId: school.id,
        id: student_attrs[:id],
        username: student_attrs[:username],
        name: student_attrs[:name],
        createdAt: now, updatedAt: now, discardedAt: nil
      )
    end

    allow(ProfileApiClient).to receive(:list_school_students).and_return(students)
  end

  def stub_profile_api_create_school_student(user_id: SecureRandom.uuid)
    allow(ProfileApiClient).to receive(:create_school_student).and_return(created: [user_id])
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
  end

  def stub_profile_api_delete_school_student
    allow(ProfileApiClient).to receive(:delete_school_student)
  end

  def stub_profile_api_create_safeguarding_flag
    allow(ProfileApiClient).to receive(:create_safeguarding_flag)
  end
end
