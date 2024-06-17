# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/invitation
class InvitationPreview < ActionMailer::Preview
  def invite_teacher
    school = School.new(name: 'Elmwood Secondary School')
    invitation = Invitation.new(email_address: 'teacher@example.com', school:)
    InvitationMailer.with(invitation:).invite_teacher
  end
end
