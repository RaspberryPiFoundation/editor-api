# Swagger API Documentation

This directory contains OpenAPI/Swagger specifications for the Editor API REST endpoints.

## Overview

We use [rswag](https://github.com/rswag/rswag) to generate interactive API documentation from RSpec request specs.

- **Specs location**: `spec/swagger/api/**/*_spec.rb`
- **Generated docs**: `swagger/v1/swagger.yaml`
- **UI endpoint**: http://localhost:3009/api-docs

## Documented Endpoints

The following API controllers are documented:

### Projects
- **projects_spec.rb**: Core project CRUD operations (list, show, create, update, delete, context)
- **projects/images_spec.rb**: Project image uploads and retrieval
- **projects/remixes_spec.rb**: Project remixing (list, show, create remixes)
- **feedback_spec.rb**: Project feedback/comments from teachers
- **school_projects_spec.rb**: School project submission workflow (finished, status, submit, unsubmit, return, complete)
- **default_projects_spec.rb**: Default project templates (HTML, Python)
- **project_errors_spec.rb**: Error reporting

### Schools & Classes
- **schools_spec.rb**: School management (list, show, create, update, delete)
- **my_school_spec.rb**: Current user's school
- **school_classes_spec.rb**: Class management (list, show, create, update, delete, import from Google Classroom)
- **school_members_spec.rb**: List all school members
- **school_owners_spec.rb**: List school owners
- **school_teachers_spec.rb**: School teacher management
- **school_students_spec.rb**: Student management (list, create, batch create, update, delete)
- **class_members_spec.rb**: Class membership (list, add, batch add, remove)

### Lessons
- **lessons_spec.rb**: Lesson management (list, show, create, update, archive/unarchive, copy)

### Authentication & Invitations
- **teacher_invitations_spec.rb**: Teacher invitation flow (show, accept)
- **google_auth_spec.rb**: Google OAuth code exchange

### Background Jobs
- **user_jobs_spec.rb**: Background job status tracking

## Generating Documentation

### Quick Command
```bash
rake swagger:generate
```

This runs `rake rswag:specs:swaggerize PATTERN="spec/swagger/**/*_spec.rb"` and generates the OpenAPI YAML file.

### Manual Generation
```bash
docker compose exec api rake rswag:specs:swaggerize PATTERN="spec/swagger/**/*_spec.rb"
```

### Viewing the Documentation
1. Ensure the Rails server is running: `docker compose up`
2. Visit http://localhost:3009/api-docs
3. Click "Authorize" and enter a Bearer token to test authenticated endpoints

## Adding New Endpoints

1. **Create a new spec file** in `spec/swagger/api/` following the naming pattern:
   ```ruby
   require 'swagger_helper'

   RSpec.describe 'API::YourController', type: :request do
     path '/api/your_endpoint' do
       get('description') do
         tags 'Your Tag'
         produces 'application/json'
         security [bearer_auth: []]

         response(200, 'successful') do
           let(:user) { create(:user) }
           let(:Authorization) { "Bearer #{user.token}" }

           after do |example|
             example.metadata[:response][:content] = {
               'application/json' => {
                 example: JSON.parse(response.body, symbolize_names: true)
               }
             }
           end

           run_test!
         end
       end
     end
   end
   ```

2. **Generate the docs**:
   ```bash
   rake swagger:generate
   ```

3. **Refresh the browser** at http://localhost:3009/api-docs to see the new endpoint

## Configuration

- **swagger_helper.rb**: OpenAPI spec configuration (title, version, security schemes)
- **config/initializers/rswag_ui.rb**: Swagger UI configuration
- **config/routes.rb**: Mounts rswag engines at `/api-docs`

## Tips

- Use `tags` to group related endpoints in the UI
- Add `description` to provide context about what an endpoint does
- Include example request/response bodies in the `schema` for clarity
- Test both success and error responses (200, 201, 404, 422, etc.)
- Use `security [bearer_auth: []]` for authenticated endpoints
- The `after` block captures actual response examples from test runs

## Current Coverage

- **42 API paths** documented across 20 spec files
- **78 response examples** (success and error cases)
- All controllers under `app/controllers/api/` are covered

## Separate from Integration Tests

These swagger specs are intentionally separate from regular integration tests in `spec/requests/api/`:
- **Integration tests** (`spec/requests/`): Comprehensive test coverage, edge cases, validation logic
- **Swagger specs** (`spec/swagger/`): API documentation focused, example-driven, shows typical usage

This separation keeps documentation specs focused and prevents them from becoming overly complex.
