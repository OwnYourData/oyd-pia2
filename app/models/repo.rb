# == Schema Information
#
# Table name: repos
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  name       :string
#  identifier :string
#  public_key :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Repo < ApplicationRecord
	belongs_to :user
	validates :user_id, presence: true
	has_many :items, dependent: :destroy
end
