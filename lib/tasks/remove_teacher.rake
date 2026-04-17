# frozen_string_literal: true

namespace :remove_teacher do
  desc 'Remove teacher from their school'
  task :run, %i[teacher_email] => :environment do |_task, args|
    teacher = UserInfoApiClient.find_user_by_email(args[:teacher_email])

    unless teacher
      Rails.logger.error("No user found for email '#{args[:teacher_email]}'. Did you spell it correctly?")
      next
    end

    role = Role.find_by(roles: { user_id: teacher[:id], role: 'teacher' })

    unless role
      Rails.logger.error("No teacher role found for user with email '#{args[:teacher_email]}'. Is this the right user?")
      next
    end

    Rails.logger.info("Deleting '#{role[:role]}' role for user '#{args[:teacher_email]}' in school '#{role.school.name}'")
    role.destroy!

    Rails.logger.info "Removed teacher role for #{args[:teacher_email]} successfully."
    Rails.logger.warn '⚠️ You must now manually remove the teacher safeguarding flag for the teacher.'
    Rails.logger.warn 'Open a bash console on the rpf-profile app: `heroku run bash -a rpf-profile`'
    Rails.logger.warn "Remove the teacher safeguarding flag: `node profile-cli remove-safeguarding-flag #{args[:teacher_email]} school:teacher`"
  end
end
