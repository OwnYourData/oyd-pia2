# == Schema Information
#
# Table name: oyd_source_piles
#
#  id            :bigint(8)        not null, primary key
#  oyd_source_id :integer
#  content       :text
#  email         :string
#  signature     :text
#  verification  :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class OydSourcePile < ApplicationRecord
	has_many :items
	belongs_to :oyd_source
	validates :oyd_source_id, presence: true
end
