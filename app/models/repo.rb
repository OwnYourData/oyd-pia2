# == Schema Information
#
# Table name: repos
#
#  id         :bigint(8)        not null, primary key
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
	has_many :oyd_source_repos, dependent: :destroy
end
