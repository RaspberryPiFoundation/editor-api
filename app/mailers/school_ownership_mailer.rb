# frozen_string_literal: true

class SchoolOwnershipMailer < ApplicationMailer
  default from: email_address_with_name('web@raspberrypi.org', 'Raspberry Pi Foundation')

  def request_ownership_transfer
    ownership_transfer = params[:ownership_transfer]
    @school = ownership_transfer.school

    mail(to: ownership_transfer.email_address,
         subject: "You've been nominated to be an owner of #{@school.name}",
         track_opens: 'true',
         message_stream: 'outbound')
  end
end
