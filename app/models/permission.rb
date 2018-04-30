# == Schema Information
#
# Table name: permissions
#
#  id              :integer          not null, primary key
#  plugin_id       :integer
#  repo_identifier :string
#  perm_type       :integer
#  perm_allow      :boolean
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Permission < ApplicationRecord
	belongs_to :oauth_application, class_name: 'Doorkeeper::Application', foreign_key: 'plugin_id'
	validates :plugin_id, presence: true
end
