class BackfillDistrictNameForUsSchools < ActiveRecord::Migration[7.2]
  def up
    School
      .where(country_code: "US")
      .where("district_name IS NULL OR BTRIM(district_name) = ''")
      .update_all(district_name: "District Unknown")
  end

  def down
    School
      .where(country_code: "US")
      .where(district_name: "District Unknown")
      .update_all(district_name: nil)
  end
end
