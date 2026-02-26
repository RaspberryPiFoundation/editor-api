# frozen_string_literal: true

namespace :school_management do
  desc 'Transfer ownership of a school'
  task :transfer_ownership, %i[old_owner_email new_owner_email keep_old_owner_as_teacher] => :environment do |_task, args|
    old_owner = UserInfoApiClient.find_user_by_email(args[:old_owner_email])
    new_owner = UserInfoApiClient.find_user_by_email(args[:new_owner_email])

    unless old_owner
      Rails.logger.error("No user found for email #{args[:old_owner_email]}. Did you spell it correctly?")
      next
    end

    unless new_owner
      Rails.logger.error("No user found for email #{args[:new_owner_email]}. Did you spell it correctly?")
      next
    end

    if Role.exists?(user_id: new_owner[:id], role: 'owner')
      Rails.logger.error("User #{new_owner[:id]} is already the owner of a school")
      next
    end

    if School.exists?(creator_id: new_owner[:id])
      Rails.logger.error("User #{new_owner[:id]} is already the creator of a school")
      next
    end

    school = Role.find_by(roles: { user_id: old_owner[:id], role: 'owner' }).school

    school.transaction do
      remove_old_owner(school, old_owner[:id], args[:keep_old_owner_as_teacher])
      assign_roles_to_new_owner(school, new_owner[:id])

      school.update!(creator_id: new_owner[:id], creator_agree_to_ux_contact: false)
    end

    Rails.logger.info "Ownership transfered to #{new_owner[:email]} successfully."
    Rails.logger.warn '⚠️ You must now manually remove the owner safeguarding flag from the old owner.'
    Rails.logger.warn 'Open a bash console on the rpf-profile app: `heroku run bash -a rpf-profile`'
    Rails.logger.warn "Remove the owner safeguarding flag from the old owner: `node profile-cli remove-safeguarding-flag #{args[:old_owner_email]} school:owner`"
  end

  def remove_old_owner(school, user_id, keep_old_owner_as_teacher)
    school.roles.owner.find_by(user_id: user_id).destroy!
    school.roles.teacher.find_by(user_id: user_id)&.destroy! unless keep_old_owner_as_teacher
  end

  def assign_roles_to_new_owner(school, user_id)
    school.roles.create!(user_id: user_id, role: 'owner')
    school.roles.find_or_create_by!(user_id: user_id, role: 'teacher')
  end
end
