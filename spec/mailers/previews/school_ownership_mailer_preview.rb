# frozen_string_literal: true

# Preview all emails at http://localhost:3009/rails/mailers/school_ownership_mailer
class SchoolOwnershipMailerPreview < ActionMailer::Preview
  NOMINEE = { id: SecureRandom.uuid, name: 'Eliseo Ortiz' }.freeze
  REQUESTED_OWNER = { id: SecureRandom.uuid, name: 'Oaklynn Duran' }.freeze

  def request_ownership_transfer
    school = School.new(name: 'Elmwood Secondary School')
    stub_user_info_api

    ownership_transfer = OwnershipTransfer.new(
      email_address: 'teacher@example.com',
      school:,
      nominated_user_id: NOMINEE[:id],
      requested_by_user_id: REQUESTED_OWNER[:id]
    )
    SchoolOwnershipMailer.with(ownership_transfer:).request_ownership_transfer
  end

  private

  def stub_user_info_api
    users = [NOMINEE, REQUESTED_OWNER]
    UserInfoApiClient.define_singleton_method(:fetch_by_ids) { |ids| users.select { |u| ids.include?(u[:id]) } }
  end
end
