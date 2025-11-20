# frozen_string_literal: true

class ProfileApiClient
  SAFEGUARDING_FLAGS = {
    teacher: 'school:teacher',
    owner: 'school:owner'
  }.freeze

  # rubocop:disable Naming/MethodName
  School = Data.define(:id, :schoolCode, :updatedAt, :createdAt, :discardedAt)
  SafeguardingFlag = Data.define(:id, :userId, :flag, :email, :createdAt, :updatedAt, :discardedAt)
  Student = Data.define(:id, :schoolId, :name, :username, :createdAt, :updatedAt, :discardedAt, :email, :ssoProviders)
  # rubocop:enable Naming/MethodName

  class Error < StandardError; end

  class Student422Error < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      if errors.is_a?(Hash)
        super(errors['errorCode'] || errors['message'])
      else
        super()
      end
    end
  end

  class UnexpectedResponse < Error
    attr_reader :response_status, :response_headers, :response_body

    def initialize(response)
      @response_status = response.status
      @response_headers = response.headers
      @response_body = response.body

      super("Unexpected response from Profile API (status code #{response.status})")
    end
  end

  class << self
    def create_school(token:, id:, code:)
      return { 'id' => id, 'schoolCode' => code } if ENV['BYPASS_OAUTH'].present?

      response = connection(token).post('/api/v1/schools') do |request|
        request.body = {
          id:,
          schoolCode: code
        }
      end

      raise UnexpectedResponse, response unless response.status == 201

      School.new(**response.body)
    end

    def school_student(token:, school_id:, student_id:)
      response = connection(token).get("/api/v1/schools/#{school_id}/students/#{student_id}")

      raise UnexpectedResponse, response unless response.status == 200

      build_student(response.body)
    end

    def list_school_students(token:, school_id:, student_ids:)
      return [] if token.blank?

      response = connection(token).post("/api/v1/schools/#{school_id}/students/list") do |request|
        request.body = student_ids
      end

      raise UnexpectedResponse, response unless response.status == 200

      response.body.map { |attrs| build_student(attrs) }
    end

    def create_school_student(token:, username:, password:, name:, school_id:)
      return nil if token.blank?

      response = connection(token).post("/api/v1/schools/#{school_id}/students") do |request|
        request.body = [{
          name: name.strip,
          username: username.strip,
          password: password.strip
        }]
      end

      raise UnexpectedResponse, response unless response.status == 201

      response.body.deep_symbolize_keys
    rescue Faraday::BadRequestError => e
      raise Student422Error, JSON.parse(e.response_body)['errors'].first
    end

    def validate_school_students(token:, students:, school_id:)
      return nil if token.blank?

      students = Array(students)
      endpoint = "/api/v1/schools/#{school_id}/students/preflight-student-upload"
      response = connection(token).post(endpoint) do |request|
        request.body = students.to_json
        request.headers['Content-Type'] = 'application/json'
      end

      raise UnexpectedResponse, response unless response.status == 200
    rescue Faraday::UnprocessableEntityError => e
      raise Student422Error, JSON.parse(e.response_body)['errors']
    end

    def create_school_students(token:, students:, school_id:, preflight: false)
      return nil if token.blank?

      students = Array(students)
      endpoint = "/api/v1/schools/#{school_id}/students"
      endpoint += '/preflight' if preflight
      response = connection(token).post(endpoint) do |request|
        request.body = students.to_json
        request.headers['Content-Type'] = 'application/json'
      end

      raise UnexpectedResponse, response unless [200, 201].include?(response.status)

      response.body.deep_symbolize_keys
    rescue Faraday::BadRequestError => e
      handle_student_creation_error(e)
    end

    def create_school_students_sso(token:, students:, school_id:)
      return nil if token.blank?

      students = Array(students)
      endpoint = "/api/v1/schools/#{school_id}/students/sso"
      response = connection(token).post(endpoint) do |request|
        request.body = students.to_json
        request.headers['Content-Type'] = 'application/json'
      end

      raise UnexpectedResponse, response unless [200, 201].include?(response.status)

      response.body.map(&:deep_symbolize_keys)
    rescue Faraday::BadRequestError => e
      handle_student_creation_error(e)
    end

    def update_school_student(token:, school_id:, student_id:, name: nil, username: nil, password: nil) # rubocop:disable Metrics/ParameterLists
      return nil if token.blank?

      response = connection(token).patch("/api/v1/schools/#{school_id}/students/#{student_id}") do |request|
        request.body = {
          name: name&.strip,
          username: username&.strip,
          password: password&.strip
        }.compact
      end

      raise UnexpectedResponse, response unless response.status == 200

      build_student(response.body)
    rescue Faraday::BadRequestError => e
      raise Student422Error, JSON.parse(e.response_body)['errors'].first
    end

    def delete_school_student(token:, school_id:, student_id:)
      return nil if token.blank?

      response = connection(token).delete("/api/v1/schools/#{school_id}/students/#{student_id}")

      raise UnexpectedResponse, response unless response.status == 204
    end

    def safeguarding_flags(token:)
      response = connection(token).get('/api/v1/safeguarding-flags')

      raise UnexpectedResponse, response unless response.status == 200

      response.body.map { |flag| SafeguardingFlag.new(**flag.symbolize_keys) }
    end

    def create_safeguarding_flag(token:, flag:, email:)
      response = connection(token).post('/api/v1/safeguarding-flags') do |request|
        request.body = { flag:, email: }
      end

      raise UnexpectedResponse, response unless [201, 303].include?(response.status)
    end

    def delete_safeguarding_flag(token:, flag:)
      response = connection(token).delete("/api/v1/safeguarding-flags/#{flag}")

      raise UnexpectedResponse, response unless response.status == 204
    end

    private

    def connection(token)
      Faraday.new(ENV.fetch('IDENTITY_URL')) do |faraday|
        faraday.request :json
        faraday.response :json
        faraday.response :raise_error
        faraday.headers = {
          'Accept' => 'application/json',
          'Authorization' => "Bearer #{token}",
          'X-API-KEY' => ENV.fetch('PROFILE_API_KEY')
        }
      end
    end

    def handle_student_creation_error(faraday_error)
      raw_error = JSON.parse(faraday_error.response_body)
      # Profile returns an array for standard errors, and json for bulk validations
      if raw_error.is_a?(Array)
        raise Error, raw_error.first['message']
      elsif raw_error['errors']
        raise Student422Error, raw_error['errors']
      else
        raise Student422Error, 'An unknown error occurred'
      end
    end

    def build_student(attrs)
      symbolized_attrs = attrs.symbolize_keys

      # As of 30/09/25 we need these defaults for backwards compatibility until profile SSO changes are released.
      # (I was tempted to refactor this handling to be more flexible, however with major profile changes around
      # the corner, it makes more sense to stick with this approach for now)
      symbolized_attrs[:email] ||= nil
      symbolized_attrs[:ssoProviders] ||= []

      Student.new(**symbolized_attrs)
    end
  end
end
