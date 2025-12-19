class EnablePgTrgmExtension < ActiveRecord::Migration[7.2]
  def change
    enable_extension 'pg_trgm'
    enable_extension 'fuzzystrmatch'
  end
end
