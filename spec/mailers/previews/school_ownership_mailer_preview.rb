# frozen_string_literal: true

# Preview all emails at http://localhost:3009/rails/mailers/school_ownership_mailer
class SchoolOwnershipMailerPreview < ActionMailer::Preview
  def request_ownership_transfer
    school = School.new(name: 'Elmwood Secondary School')
    ownership_transfer = OwnershipTransfer.new(email_address: 'teacher@example.com', school:)
    SchoolOwnershipMailer.with(ownership_transfer:).request_ownership_transfer
  end
end
