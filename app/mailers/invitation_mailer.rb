# frozen_string_literal: true

class InvitationMailer < ApplicationMailer
  default from: email_address_with_name('web@raspberrypi.org', 'Raspberry Pi Foundation')

  def invite_teacher
    @school = params[:invitation].school
    @token = params[:invitation].generate_token_for(:teacher_invitation)

    mail(to: params[:invitation].email_address,
         subject: "You have been invited to join #{@school.name}",
         track_opens: 'true',
         message_stream: 'outbound')
  end
end
