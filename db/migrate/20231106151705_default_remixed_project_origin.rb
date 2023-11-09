class DefaultRemixedProjectOrigin < ActiveRecord::Migration[7.0]
  def up
    if Rails.env.development?
      remix_origin = 'http://localhost:3010'
    elsif Rails.env.test?
      remix_origin = 'staging-editor.raspberrypi.org'
    elsif Rails.env.production?
      remix_origin = 'editor.raspberrypi.org'
    end
    Project.where.not(remixed_from_id: nil).update(remix_origin: remix_origin)
  end

  def down
    Project.update(remix_origin: nil)
  end
end
