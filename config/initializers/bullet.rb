# frozen_string_literal: true

Bullet.add_safelist type: :unused_eager_loading, class_name: 'Project', association: :images_attachments if Rails.env.local?
