if Rails.env.development? || Rails.env.test?
  Bullet.add_safelist type: :unused_eager_loading, class_name: 'Project', association: :images_attachments
end