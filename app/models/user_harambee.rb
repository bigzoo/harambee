class UserHarambee < ApplicationRecord
  has_many :transactions
  belongs_to :user
end
