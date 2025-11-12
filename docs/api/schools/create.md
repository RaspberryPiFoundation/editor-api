# POST /api/schools

Create a new school and assign the authenticated user as its owner. This endpoint is used by educators registering their institution in the Raspberry Pi for Education platform.

## Authentication and authorisation

- Send an `Authorization: Bearer <token>` header. Tokens are resolved via `User.from_token`.
- Only authenticated, non-student accounts can create schools. Requests from anonymous or student users are rejected.
- Each user can create at most one school; the server enforces this via a unique `creator_id` constraint.

## Request body

The request payload must be nested under a top-level `school` key. Unless marked optional, fields are required.

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | string | Yes | Display name for the school. |
| `website` | string | Yes | Must be a valid HTTP(S) URL; validated with a relaxed URL regex. |
| `reference` | string | Optional | External reference code. Empty strings are treated as `null`. Must be unique if present. |
| `address_line_1` | string | Yes | First line of the address. |
| `address_line_2` | string | Optional | Second address line. |
| `municipality` | string | Yes | City, town, or municipality. |
| `administrative_area` | string | Optional | County, state, or regional area. |
| `postal_code` | string | Optional | If the `country_code` is `GB`, it will be capitalised and formatted automatically when 5+ characters. |
| `country_code` | string | Yes | ISO 3166-1 alpha-2 country code. |
| `creator_role` | string | Optional | Role of the creator within the institution. |
| `creator_department` | string | Optional | Department of the creator. |
| `creator_agree_authority` | boolean | Yes | Must be `true`; indicates the creator has authority to register the school. |
| `creator_agree_terms_and_conditions` | boolean | Yes | Must be `true`; acceptance of terms and conditions. |
| `creator_agree_to_ux_contact` | boolean | Optional | Defaults to `false`. Allows UX research contact. |
| `creator_agree_responsible_safeguarding` | boolean | Yes | Must be `true`; confirms safeguarding responsibility. |
| `user_origin` | string | Optional | Enum: `for_education` (default) or `experience_cs`. |

`creator_id` is set automatically from the authenticated user and cannot be supplied manually.

## Example request

```bash
curl -X POST "https://editor.raspberrypi.org/api/schools" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "school": {
      "name": "Example High School",
      "website": "https://www.examplehighschool.edu",
      "address_line_1": "123 Example Street",
      "municipality": "Cambridge",
      "administrative_area": "Cambridgeshire",
      "postal_code": "CB12 3AB",
      "country_code": "GB",
      "creator_role": "Head Teacher",
      "creator_department": "STEM",
      "creator_agree_authority": true,
      "creator_agree_terms_and_conditions": true,
      "creator_agree_to_ux_contact": false,
      "creator_agree_responsible_safeguarding": true,
      "user_origin": "for_education"
    }
  }'
```

## Successful response

On success, the server returns HTTP `201 Created` with the newly created school in JSON form:

```json
{
  "id": "3a46c3c2-02c5-4ee0-8f4b-6fd613f3e6a1",
  "name": "Example High School",
  "website": "https://www.examplehighschool.edu",
  "reference": null,
  "address_line_1": "123 Example Street",
  "address_line_2": null,
  "municipality": "Cambridge",
  "administrative_area": "Cambridgeshire",
  "postal_code": "CB12 3AB",
  "country_code": "GB",
  "verified_at": null,
  "created_at": "2025-09-30T11:42:18Z",
  "updated_at": "2025-09-30T11:42:18Z",
  "user_origin": "for_education"
}
```

Additional fields such as `roles` or `code` are omitted in this response; they are only included in other API contexts that explicitly request them.

## Error responses

| Status | When it occurs | Payload |
| --- | --- | --- |
| `401 Unauthorized` | Missing or invalid bearer token. | Empty body. |
| `403 Forbidden` | Authenticated user lacks permission (e.g. a student account). | Empty body. |
| `422 Unprocessable Entity` | Validation failed (missing required fields, invalid URL, duplicate creator, etc.). | `{ "error": { "field": ["message", ...] } }` |

Example validation failure:

```json
{
  "error": {
    "name": ["can't be blank"],
    "website": ["is invalid"],
    "creator_agree_terms_and_conditions": ["must be accepted"],
    "creator_agree_responsible_safeguarding": ["must be accepted"],
    "creator_agree_authority": ["must be accepted"],
    "country_code": ["can't be blank"],
    "address_line_1": ["can't be blank"],
    "municipality": ["can't be blank"]
  }
}
```

For duplicate submissions from the same user, the `creator_id` uniqueness constraint surfaces as a `422` response with an error on `creator`. After a successful creation, subsequent attempts by the same user should use the existing school rather than calling this endpoint again.
