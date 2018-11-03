# == Schema Information
#
# Table name: merkles
#
#  id              :bigint(8)        not null, primary key
#  payload         :text
#  root_hash       :string
#  oyd_transaction :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  merkle_tree     :text
#

class Merkle < ApplicationRecord
	has_many :items
end
