require 'rails_helper'

RSpec.describe SchoolEmailDomain, type: :model do
    let(:school) { create(:school, creator_id: SecureRandom.uuid) }
    
    let(:school_email_domain) do
        described_class.new(school: school, domain: 'example.edu')
      end
    
    it 'has a school' do
        expect(school_email_domain.school_id).to eq(school.id)
    end

    it 'has a domain' do
        expect(school_email_domain.domain).to eq('example.edu')
    end
end