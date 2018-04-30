# == Schema Information
#
# Table name: plugin_details
#
#  id          :integer          not null, primary key
#  description :string
#  info_url    :string
#  picture     :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  identifier  :string
#

class PluginDetail < ApplicationRecord
	has_many :oyd_views
end
