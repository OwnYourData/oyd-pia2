# == Schema Information
#
# Table name: plugin_assists
#
#  id         :bigint(8)        not null, primary key
#  user_id    :integer
#  identifier :string
#  assist     :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class PluginAssist < ApplicationRecord
	belongs_to :user
	validates :user_id, presence: true
end
