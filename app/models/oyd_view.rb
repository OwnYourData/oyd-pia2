# == Schema Information
#
# Table name: oyd_views
#
#  id               :integer          not null, primary key
#  plugin_id        :integer
#  plugin_detail_id :integer
#  name             :string
#  identifier       :string
#  url              :string
#  view_type        :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class OydView < ApplicationRecord
	belongs_to :oauth_application, class_name: 'Doorkeeper::Application', foreign_key: 'plugin_id'
	validates :plugin_id, presence: true
	belongs_to :plugin_detail
end
