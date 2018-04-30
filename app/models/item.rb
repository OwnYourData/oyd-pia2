# == Schema Information
#
# Table name: items
#
#  id         :integer          not null, primary key
#  repo_id    :integer
#  merkle_id  :integer
#  value      :text
#  oyd_hash   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Item < ApplicationRecord
	belongs_to :repo
	belongs_to :merkle, optional: true
	validates :repo_id, presence: true
end
