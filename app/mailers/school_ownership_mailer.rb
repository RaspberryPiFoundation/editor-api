# frozen_string_literal: true

class SchoolOwnershipMailer < ApplicationMailer
  default from: email_address_with_name('web@raspberrypi.org', 'Raspberry Pi Foundation')

  def request_ownership_transfer
    @school = params[:ownership_transfer].school
    @token = params[:ownership_transfer].generate_token_for(:ownership_transfer)

    mail(to: params[:ownership_transfer].email_address,
         subject: "You have been asked to take ownership of #{@school.name}",
         track_opens: 'true',
         message_stream: 'outbound')
  end
end
