# == Schema Information
#
# Table name: logs
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  plugin_id  :integer
#  identifier :string
#  message    :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Log < ApplicationRecord
	belongs_to :user, optional: true
	belongs_to :oauth_application, class_name: 'Doorkeeper::Application', foreign_key: 'plugin_id', optional: true
end
