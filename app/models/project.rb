class Project < ApplicationRecord
  has_many :components, dependent: :destroy
end
