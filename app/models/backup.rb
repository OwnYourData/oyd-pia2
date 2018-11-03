# == Schema Information
#
# Table name: backups
#
#  id         :bigint(8)        not null, primary key
#  user_id    :integer
#  location   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  comment    :string
#

class Backup < ApplicationRecord
	belongs_to :user
	validates :user_id, presence: true
end
