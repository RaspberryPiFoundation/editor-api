# frozen_string_literal: true

class SalesforceSyncJob < ApplicationJob
  def perform(school_id)
    school = School.find(school_id)

    account_data = {
      Name: school.name,
      Website: school.website,
      BillingStreet: [school.address_line_1, school.address_line_2].compact.join("\n"),
      BillingCity: school.municipality,
      BillingState: school.administrative_area,
      BillingPostalCode: school.postal_code,
      BillingCountryCode: school.country_code,
      Industry: 'Education'
    }

    client.create('Account', account_data)
  end

  private

  def client
    Restforce.new(
      username: ENV.fetch('SALESFORCE_USERNAME'),
      password: ENV.fetch('SALESFORCE_PASSWORD'),
      client_id: ENV.fetch('SALESFORCE_CLIENT_ID'),
      client_secret: ENV.fetch('SALESFORCE_CLIENT_SECRET'),
      host: ENV.fetch('SALESFORCE_HOST'),
      api_version: '57.0'
    )
  end
end
