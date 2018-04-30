# == Schema Information
#
# Table name: oyd_task_templates
#
#  id         :integer          not null, primary key
#  plugin_id  :integer
#  identifier :string
#  command    :text
#  schedule   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class OydTaskTemplate < ApplicationRecord
	belongs_to :oauth_application, class_name: 'Doorkeeper::Application', foreign_key: 'plugin_id'
	validates :plugin_id, presence: true
end
