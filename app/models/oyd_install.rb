# == Schema Information
#
# Table name: oyd_installs
#
#  id           :bigint(8)        not null, primary key
#  plugin_id    :integer
#  code         :string
#  requested_ts :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class OydInstall < ApplicationRecord
	belongs_to :oauth_application, class_name: 'Doorkeeper::Application', foreign_key: 'plugin_id'
	validates :plugin_id, presence: true
end
