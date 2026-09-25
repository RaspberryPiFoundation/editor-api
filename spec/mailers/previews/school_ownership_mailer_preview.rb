# frozen_string_literal: true

# Preview all emails at http://localhost:3009/rails/mailers/school_ownership_mailer
class SchoolOwnershipMailerPreview < ActionMailer::Preview
  NOMINEE = { id: SecureRandom.uuid, name: 'Eliseo Ortiz' }.freeze
  REQUESTED_OWNER = { id: SecureRandom.uuid, name: 'Oaklynn Duran' }.freeze

  def request_ownership_transfer
    school = School.new(name: 'Elmwood Secondary School')
    ownership_transfer = OwnershipTransfer.new(
      email_address: 'teacher@example.com',
      school:,
      nominated_user_id: NOMINEE[:id],
      requested_by_user_id: REQUESTED_OWNER[:id]
    )

    with_stubbed_user_info_api { SchoolOwnershipMailer.with(ownership_transfer:).request_ownership_transfer.message }
  end

  def cancel_ownership_transfer
    school = School.new(name: 'Elmwood Secondary School')
    ownership_transfer = OwnershipTransfer.new(
      email_address: 'teacher@example.com',
      school:,
      nominated_user_id: NOMINEE[:id],
      requested_by_user_id: REQUESTED_OWNER[:id],
      status: :cancelled
    )

    with_stubbed_user_info_api { SchoolOwnershipMailer.with(ownership_transfer:).cancel_ownership_transfer.message }
  end

  def complete_ownership_transfer
    school = School.new(name: 'Elmwood Secondary School')
    ownership_transfer = OwnershipTransfer.new(
      email_address: 'teacher@example.com',
      school:,
      nominated_user_id: NOMINEE[:id],
      requested_by_user_id: REQUESTED_OWNER[:id],
      status: :completed
    )

    with_stubbed_user_info_api { SchoolOwnershipMailer.with(ownership_transfer:).complete_ownership_transfer.message }
  end

  private

  # fake the user info response, but only for the duration of
  # this call, so other previews/requests in the same dev server aren't affected
  def with_stubbed_user_info_api
    users = [NOMINEE, REQUESTED_OWNER]
    original_fetch_by_ids = UserInfoApiClient.method(:fetch_by_ids)

    UserInfoApiClient.define_singleton_method(:fetch_by_ids) { |ids| users.select { |u| ids.include?(u[:id]) } }
    yield
  ensure
    UserInfoApiClient.define_singleton_method(:fetch_by_ids, original_fetch_by_ids)
  end
end
