# Auto-generated OpenAPI Documentation with rspec-openapi

This setup uses **[rspec-openapi](https://github.com/exoego/rspec-openapi)** to automatically generate OpenAPI specs from your existing request specs. The controller code and actual request/response behavior are the source of truth.

## How It Works

When you run request specs with `OPENAPI=1`, rspec-openapi:
1. Captures actual HTTP requests/responses from your tests
2. Infers schemas from real data
3. Merges new endpoints into `swagger/v1/swagger.yaml`
4. Preserves manual edits/descriptions

**No annotations or DSL required** - it uses your existing tests as-is.

## Usage

### Generate Full API Documentation

```bash
rake openapi:generate
```

This runs all request specs in `spec/requests/` and generates/updates the OpenAPI spec.

### Regenerate for Specific Endpoint

```bash
# By file
rake openapi:generate_one[spec/requests/projects/show_spec.rb]

# Or using environment variable
SPEC=spec/requests/projects/show_spec.rb rake openapi:generate_one
```

### Manual Command

```bash
# All request specs
OPENAPI=1 bundle exec rspec spec/requests/

# Specific controller
OPENAPI=1 bundle exec rspec spec/requests/projects/

# Single spec file
OPENAPI=1 bundle exec rspec spec/requests/projects/show_spec.rb
```

## Viewing the Docs

Visit **http://localhost:3009/api-docs** (rswag UI still works with auto-generated specs).

## How It Stays in Sync

### ✅ Automatic Sync Benefits

1. **Delete an endpoint** → Remove its controller/action → Delete the request spec → Run `rake openapi:generate` → Endpoint disappears from docs

2. **Add an endpoint** → Implement controller action → Write request spec → Run `rake openapi:generate` → Endpoint appears in docs

3. **Change response structure** → Update controller → Request spec fails → Fix spec → Run `rake openapi:generate` → Docs automatically update

4. **Rename parameters** → Change controller → Request specs guide refactor → Run `rake openapi:generate` → Docs reflect changes

### 🔄 When Docs Update

- **Automatically**: When CI runs request specs with `OPENAPI=1`
- **Manually**: Run `rake openapi:generate` after changes
- **Per-feature**: Run specs for changed endpoint only

## CI Integration

Add to your GitHub Actions or CI pipeline:

```yaml
# .github/workflows/test.yml
- name: Run tests and generate API docs
  run: |
    docker compose exec -T api bash -c "OPENAPI=1 bundle exec rspec spec/requests/"

- name: Check if docs changed
  run: |
    if git diff --quiet swagger/v1/swagger.yaml; then
      echo "✅ API docs are up to date"
    else
      echo "📝 API docs were updated"
      git add swagger/v1/swagger.yaml
      # Optionally commit or create PR
    fi
```

## Configuration

See `config/initializers/rspec_openapi.rb` for:
- Title, version, description
- Server URLs (dev/production)
- Security schemes (Bearer auth)
- Paths to ignore (admin, test endpoints)
- Headers to include/exclude

## What Gets Documented

rspec-openapi automatically captures:

### From Controllers
- ✅ Route paths (from `config/routes.rb`)
- ✅ HTTP methods (GET, POST, PUT, DELETE, etc.)
- ✅ Path parameters (`/api/projects/{identifier}`)
- ✅ Query parameters (inferred from request specs)

### From Request Specs
- ✅ Request headers (Authorization, Content-Type)
- ✅ Request body schemas (from test data)
- ✅ Response status codes (200, 404, 422, etc.)
- ✅ Response body schemas (from actual responses)
- ✅ Examples (real data from tests)

### From Test Names
- ✅ Operation summaries (from `it` or `context` descriptions)
- ✅ Tags (from controller namespace)

## Customizing Documentation

While rspec-openapi is automatic, you can enhance docs:

### Add Descriptions via Test Names

```ruby
RSpec.describe 'Projects API' do
  context 'when fetching a project by identifier' do  # ← Becomes operation description
    it 'returns the project with all components' do
      get "/api/projects/#{project.identifier}", headers:
      expect(response).to have_http_status(:ok)
    end
  end
end
```

### Exclude Specific Tests

```ruby
it 'handles edge case', openapi: false do  # ← Won't be documented
  # Test something that shouldn't be in public API docs
end
```

### Manual Post-Processing

Edit `swagger/v1/swagger.yaml` directly to:
- Add richer descriptions
- Add examples
- Group operations with tags
- Add response headers

rspec-openapi will preserve manual edits when merging new endpoints.

## Comparison with rswag Approach

| Aspect | rspec-openapi (current) | rswag (manual specs) |
|--------|------------------------|----------------------|
| **Source of truth** | Controller + request specs | Separate swagger specs |
| **Maintenance** | Zero - docs auto-update | Manual - must update separately |
| **Annotations** | None required | DSL annotations in specs |
| **Sync risk** | Never drifts | Can drift if forgotten |
| **Endpoint removed** | Automatic removal | Manual deletion needed |
| **Control** | Less granular | Fine-grained |
| **Setup effort** | Minimal | More upfront |

## Troubleshooting

### Docs not updating?

```bash
# Force regeneration
rm swagger/v1/swagger.yaml
rake openapi:generate
```

### Want to exclude an endpoint?

Add to `config/initializers/rspec_openapi.rb`:

```ruby
RSpec::OpenAPI.ignored_paths = [
  %r{^/admin},
  %r{^/test},
  %r{^/internal}
]
```

### Specs failing with OPENAPI=1?

The rspec-openapi hook runs `after(:each)` for `:request` type specs. If specs are failing, fix the tests first - docs generation happens after successful test runs.

## Benefits Summary

✅ **Always accurate** - Docs generated from actual behavior
✅ **Zero maintenance** - No separate files to keep in sync
✅ **Automatic cleanup** - Removed endpoints disappear from docs
✅ **Test-driven** - Docs only include tested endpoints
✅ **Controller-based** - Source of truth is your code, not specs
✅ **CI-friendly** - Easy to automate and validate

The key advantage: **If you delete a controller action or request spec, the documentation automatically reflects that change.** No separate swagger spec files to remember to update or delete.
