# frozen_string_literal: true

class InvitationMailer < ApplicationMailer
  default from: email_address_with_name('websupport@raspberrypi.org', 'Raspberry Pi Foundation')

  def invite_teacher
    @school = params[:invitation].school
    mail(to: params[:invitation].email_address,
         subject: "You have been invited to join #{@school.name}")
  end
end
