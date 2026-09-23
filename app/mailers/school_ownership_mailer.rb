# frozen_string_literal: true

class SchoolOwnershipMailer < ApplicationMailer
  default from: email_address_with_name('web@raspberrypi.org', 'Raspberry Pi Foundation')

  def request_ownership_transfer
    @school = ownership_transfer.school

    @nominee_name = users_by_id[ownership_transfer.nominated_user_id]&.name.presence || 'there'
    @requested_owner_name = users_by_id[ownership_transfer.requested_by_user_id]&.name.presence || 'The school owner'

    mail(to: ownership_transfer.email_address,
         subject: "You've been nominated to be an owner of #{@school.name}",
         track_opens: 'true',
         message_stream: 'outbound')
  end

  def cancel_ownership_transfer
    @school = ownership_transfer.school
    @nominee_name = users_by_id[ownership_transfer.nominated_user_id]&.name.presence || 'there'

    mail(to: ownership_transfer.email_address,
         subject: "The ownership nomination for #{@school.name} has been cancelled",
         track_opens: 'true',
         message_stream: 'outbound')
  end

  def complete_ownership_transfer
    @school = ownership_transfer.school
    @new_owner_name = users_by_id[ownership_transfer.nominated_user_id]&.name.presence || 'there'

    mail(to: ownership_transfer.email_address,
         subject: "You're now the owner of the Code Classroom account for #{@school.name}",
         track_opens: 'true',
         message_stream: 'outbound')
  end

  private

  def ownership_transfer
    params[:ownership_transfer]
  end

  def users_by_id
    @users_by_id ||= User.from_userinfo(
      ids: [ownership_transfer.nominated_user_id, ownership_transfer.requested_by_user_id]
    ).index_by(&:id)
  end
end
