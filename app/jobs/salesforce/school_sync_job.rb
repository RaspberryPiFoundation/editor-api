# frozen_string_literal: true

module Salesforce
  class SchoolSyncJob < SalesforceSyncJob
    MODEL_CLASS = Salesforce::School

    FIELD_MAPPINGS = {
      editoruuid__c: :id,
      name: :name,
      editorreference__c: :reference,
      addressline1__c: :address_line_1,
      addressline2__c: :address_line_2,
      editormunicipality__c: :municipality,
      editoradministrativearea__c: :administrative_area,
      postcode__c: :postal_code,
      countrycode__c: :country_code,
      verifiedat__c: :verified_at,
      createdat__c: :created_at,
      updatedat__c: :updated_at,
      rejectedat__c: :rejected_at,
      website__c: :website,
      userorigin__c: :user_origin,
      districtnamesupplied__c: :district_name,
      ncesid__c: :district_nces_id,
      schoolrollnumber__c: :school_roll_number
    }.freeze

    def perform(school_id:)
      school = ::School.find(school_id)

      sf_school = Salesforce::School.find_or_initialize_by(editoruuid__c: school_id)
      sf_school.attributes = sf_school_attributes(school:)
      sf_school.save!
    end

    private

    def sf_school_attributes(school:)
      mapped_attributes(school:).to_h do |sf_field, value|
        value = 'for_education' if sf_field == :userorigin__c && value.nil?
        value = truncate_value(sf_field:, value:) if value.is_a?(String)

        [sf_field, value]
      end
    end

    def mapped_attributes(school:)
      FIELD_MAPPINGS.transform_values do |school_field|
        school.send(school_field)
      end
    end
  end
end
