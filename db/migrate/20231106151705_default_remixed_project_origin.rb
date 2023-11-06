class DefaultRemixedProjectOrigin < ActiveRecord::Migration[7.0]
  def up
    if Rails.env.development?
      remix_origin = 'http://localhost:3010'
    elsif Rails.env.test?
      remix_origin = 'staging-editor.raspberrypi.org'
    elsif Rails.env.production?
      remix_origin = 'editor.raspberrypi.org'
    end
    Project.find_each do |project|
      project.update_attribute(:remix_origin, remix_origin) unless project.remixed_from_id.nil?
    end
  end

  def down
    Project.find_each do |project|
      project.update_attribute(:remix_origin, nil)
    end
  end
end
