# == Schema Information
#
# Table name: oyd_sources
#
#  id                :bigint(8)        not null, primary key
#  plugin_id         :integer
#  name              :string
#  description       :string
#  source_type       :string
#  config            :text
#  config_values     :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  configured        :boolean
#  assist_check      :boolean
#  identifier        :string
#  inactive_duration :integer
#  inactive_text     :string
#  inactive_check    :boolean
#

class OydSource < ApplicationRecord
	belongs_to :oauth_application, class_name: 'Doorkeeper::Application', foreign_key: 'plugin_id'
	has_many :oyd_source_repos, dependent: :destroy
	validates :plugin_id, presence: true
end
