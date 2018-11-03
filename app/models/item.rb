# == Schema Information
#
# Table name: items
#
#  id                 :bigint(8)        not null, primary key
#  repo_id            :integer
#  merkle_id          :integer
#  value              :text
#  oyd_hash           :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  oyd_source_pile_id :integer
#

class Item < ApplicationRecord
	belongs_to :repo
	validates :repo_id, presence: true
	belongs_to :merkle, optional: true
	belongs_to :oyd_source_pile, optional: true
end
