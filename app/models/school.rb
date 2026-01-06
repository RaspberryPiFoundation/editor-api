# frozen_string_literal: true

class School < ApplicationRecord
  has_many :classes, class_name: :SchoolClass, inverse_of: :school, dependent: :destroy
  has_many :lessons, dependent: :nullify
  has_many :projects, dependent: :nullify
  has_many :roles, dependent: :nullify
  has_many :school_projects, dependent: :nullify

  VALID_URL_REGEX = %r{\A(?:https?://)?(?:www.)?[a-z0-9]+([-.]{1}[a-z0-9]+)*\.[a-z]{2,63}(\.[a-z]{2,63})*(/.*)?\z}ix

  enum :user_origin, { for_education: 0, experience_cs: 1 }, default: :for_education, validate: true

  validates :name, presence: true
  validates :website, presence: true, format: { with: VALID_URL_REGEX, message: I18n.t('validations.school.website') }
  validates :address_line_1, presence: true
  validates :municipality, presence: true
  validates :administrative_area, presence: true
  validates :postal_code, presence: true
  validates :country_code, presence: true, inclusion: { in: ISO3166::Country.codes }
  validates :reference,
            uniqueness: { conditions: -> { where(rejected_at: nil) }, case_sensitive: false, allow_blank: true, message: I18n.t('validations.school.reference_urn_exists') },
            format: { with: /\A\d{5,6}\z/, allow_nil: true, message: I18n.t('validations.school.reference') },
            if: :united_kingdom?
  validates :district_nces_id,
            uniqueness: { conditions: -> { where(rejected_at: nil) }, case_sensitive: false, allow_blank: true, message: I18n.t('validations.school.district_nces_id_exists') },
            format: { with: /\A\d{12}\z/, allow_nil: true, message: I18n.t('validations.school.district_nces_id') },
            presence: true,
            if: :united_states?
  validates :district_name, presence: true, if: :united_states?
  validates :school_roll_number,
            uniqueness: { conditions: -> { where(rejected_at: nil) }, case_sensitive: false, allow_blank: true, message: I18n.t('validations.school.school_roll_number_exists') },
            format: { with: /\A[0-9]+[A-Z]+\z/, allow_nil: true, message: I18n.t('validations.school.school_roll_number') },
            presence: true,
            if: :ireland?
  validates :creator_id, presence: true, uniqueness: true
  validates :creator_agree_authority, presence: true, acceptance: true
  validates :creator_agree_terms_and_conditions, presence: true, acceptance: true
  validates :creator_agree_responsible_safeguarding, presence: true, acceptance: true
  validates :rejected_at, absence: { if: proc { |school| school.verified? } }
  validates :verified_at, absence: { if: proc { |school| school.rejected? } }
  validates :code,
            uniqueness: { allow_nil: true },
            format: { with: /\d\d-\d\d-\d\d/, allow_nil: true }
  validate :verified_at_cannot_be_changed
  validate :code_cannot_be_changed

  before_validation :normalize_reference
  before_validation :normalize_district_fields
  before_validation :normalize_school_roll_number

  before_save :format_uk_postal_code, if: :should_format_uk_postal_code?

  after_commit :generate_code!, on: :create, if: -> { FeatureFlags.immediate_school_onboarding? }

  def self.find_for_user!(user)
    school = Role.find_by(user_id: user.id)&.school || find_by(creator_id: user.id)
    raise ActiveRecord::RecordNotFound unless school

    school
  end

  def creator
    User.from_userinfo(ids: creator_id).first
  end

  def verified?
    verified_at.present?
  end

  def rejected?
    rejected_at.present?
  end

  def verify!
    generate_code! if ENV['ENABLE_IMMEDIATE_SCHOOL_ONBOARDING'].blank?

    update!(verified_at: Time.zone.now)
  end

  def generate_code!
    return code if code.present?

    attempts = 0
    begin
      new_code = ForEducationCodeGenerator.generate
      update!(code: new_code)
    rescue ActiveRecord::RecordInvalid => e
      raise unless e.record.errors[:code].include?('has already been taken') && attempts <= 5

      attempts += 1
      retry
    end
  end

  def reject
    update(rejected_at: Time.zone.now)
  end

  def reopen
    return false unless rejected?

    update(rejected_at: nil)
  end

  def postal_code=(str)
    super(str.to_s.upcase)
  end

  # This method returns true if there is an existing, unfinished, batch whose description
  # matches the current school ID. This prevents two users enqueueing a batch for
  # the same school, since GoodJob::Batch doesn't support a concurrency key.
  def import_in_progress?
    GoodJob::BatchRecord.where(finished_at: nil)
                        .where(discarded_at: nil)
                        .exists?(description: id)
  end

  private

  # Ensure the reference is nil, not an empty string
  def normalize_reference
    self.reference = nil if reference.blank?
  end

  # Ensure district fields are nil, not empty strings
  def normalize_district_fields
    self.district_name = nil if district_name.blank?
    self.district_nces_id = nil if district_nces_id.blank?
  end

  # Ensure the school_roll_number is nil, not an empty string
  # Also normalize to uppercase for consistent validation
  def normalize_school_roll_number
    self.school_roll_number = school_roll_number.blank? ? nil : school_roll_number.upcase
  end

  def verified_at_cannot_be_changed
    errors.add(:verified_at, 'cannot be changed after verification') if verified_at_was.present? && verified_at_changed?
  end

  def rejected_at_cannot_be_changed
    errors.add(:rejected_at, 'cannot be changed after rejection') if rejected_at_was.present? && rejected_at_changed?
  end

  def code_cannot_be_changed
    errors.add(:code, 'cannot be changed after onboarding') if code_was.present? && code_changed?
  end

  def should_format_uk_postal_code?
    country_code == 'GB' && postal_code.to_s.length >= 5
  end

  def united_kingdom?
    country_code == 'GB'
  end

  def united_states?
    country_code == 'US'
  end

  def ireland?
    country_code == 'IE'
  end

  def format_uk_postal_code
    cleaned_postal_code = postal_code.delete(' ')
    # insert a space as the third-from-last character in the postcode, eg. SW1A1AA -> SW1A 1AA
    # ensures UK postcodes are always formatted correctly (as the inward code is always 3 chars long)
    self.postal_code = "#{cleaned_postal_code[0..-4]} #{cleaned_postal_code[-3..]}"
  end
end
