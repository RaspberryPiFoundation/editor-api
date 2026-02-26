# frozen_string_literal: true

class EnumField < Administrate::Field::Select
  def to_s
    # Use Rails' i18n for enums
    return if data.blank?

    I18n.t(
      "activerecord.attributes.#{resource.class.model_name.i18n_key}.#{attribute}_values.#{data}",
      default: data.humanize
    )
  end
end
