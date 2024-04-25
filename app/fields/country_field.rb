require 'administrate/field/base'

class CountryField < Administrate::Field::Base
  def to_s
    ISO3166::Country.find_country_by_alpha2(data)
  end
end
