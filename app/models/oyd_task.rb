# == Schema Information
#
# Table name: oyd_tasks
#
#  id         :bigint(8)        not null, primary key
#  plugin_id  :integer
#  identifier :string
#  command    :text
#  schedule   :string
#  next_run   :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class OydTask < ApplicationRecord
	belongs_to :oauth_application, class_name: 'Doorkeeper::Application', foreign_key: 'plugin_id', optional: true
end
