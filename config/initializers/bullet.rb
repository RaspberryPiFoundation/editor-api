# frozen_string_literal: true

if Rails.env.development? || Rails.env.test?
  Bullet.add_safelist type: :unused_eager_loading, class_name: 'Project', association: :images_attachments
  Bullet.add_safelist type: :n_plus_one_query, class_name: 'Project', association: :scratch_component
end
