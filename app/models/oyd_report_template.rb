# == Schema Information
#
# Table name: oyd_report_templates
#
#  id         :integer          not null, primary key
#  plugin_id  :integer
#  identifier :string
#  data_prep  :text
#  data_view  :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class OydReportTemplate < ApplicationRecord
	belongs_to :oauth_application, class_name: 'Doorkeeper::Application', foreign_key: 'plugin_id'
	validates :plugin_id, presence: true
end
