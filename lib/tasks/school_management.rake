# frozen_string_literal: true

namespace :school_management do
  desc 'Transfer ownership of a school'
  task :transfer_ownership, %i[old_owner_email new_owner_email keep_old_owner_as_teacher] => :environment do |_task, args|
    keep_old_owner_as_teacher = ActiveModel::Type::Boolean.new.cast(args[:keep_old_owner_as_teacher])

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

    school = Role.find_by(user_id: old_owner[:id], role: 'owner')&.school

    unless school
      Rails.logger.error("User #{old_owner[:id]} is not the owner of a school")
      next
    end

    result = nil

    school.transaction do
      teacher_role = Role.unscoped.teacher.find_or_initialize_by(school:, user_id: new_owner[:id])
      teacher_role.update!(archived_at: nil)

      result = OwnershipTransfer::Create.call(
        school:,
        nominated_user_id: new_owner[:id],
        requested_by_user_id: old_owner[:id],
        skip_request_email: true
      )

      raise ActiveRecord::Rollback unless result.success?
    end

    unless result.success?
      Rails.logger.error("Could not create ownership transfer: #{result[:error].inspect}")
      next
    end

    school.transaction do
      OwnershipTransfer::Accept.call(ownership_transfer: result[:ownership_transfer])
      school.roles.teacher.find_by(user_id: old_owner[:id])&.archive! unless keep_old_owner_as_teacher
      school.update!(creator_agree_to_ux_contact: false)
    end

    Rails.logger.info "Ownership transfered to #{new_owner[:email]} successfully."
    Rails.logger.warn '⚠️ You must now manually remove the owner safeguarding flag from the old owner.'
    Rails.logger.warn 'Open a bash console on the rpf-profile app: `heroku run bash -a rpf-profile`'
    Rails.logger.warn "Remove the owner safeguarding flag from the old owner: `node profile-cli remove-safeguarding-flag #{args[:old_owner_email]} school:owner`"
  end
end
