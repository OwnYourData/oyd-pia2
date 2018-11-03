# == Schema Information
#
# Table name: oyd_reports
#
#  id           :bigint(8)        not null, primary key
#  plugin_id    :integer
#  identifier   :string
#  data_prep    :text
#  report_view  :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  current      :text
#  name         :string
#  info_url     :string
#  data_snippet :text
#  report_order :integer
#  repos        :text
#

class OydReport < ApplicationRecord
	belongs_to :oauth_application, class_name: 'Doorkeeper::Application', foreign_key: 'plugin_id'
	validates :plugin_id, presence: true
end
