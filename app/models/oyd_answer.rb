# == Schema Information
#
# Table name: oyd_answers
#
#  id           :bigint(8)        not null, primary key
#  plugin_id    :integer
#  name         :string
#  identifier   :string
#  category     :string
#  info_url     :string
#  repos        :text
#  answer_order :integer
#  answer_view  :text
#  answer_logic :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  short        :string
#

class OydAnswer < ApplicationRecord
	belongs_to :oauth_application, class_name: 'Doorkeeper::Application', foreign_key: 'plugin_id'
	validates :plugin_id, presence: true
end
