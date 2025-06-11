# frozen_string_literal: true

json.partial! '/api/schools/school', school: @school, roles: @user.school_roles(@school), code: true
