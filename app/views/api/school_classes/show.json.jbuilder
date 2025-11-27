# frozen_string_literal: true

school_class, teachers = @school_class_with_teachers

json.partial! 'school_class', school_class: school_class, teachers: teachers

json.code school_class.code
