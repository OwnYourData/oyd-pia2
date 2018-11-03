# == Schema Information
#
# Table name: oyd_source_repos
#
#  id            :bigint(8)        not null, primary key
#  oyd_source_id :integer
#  repo_id       :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  stats         :boolean
#

class OydSourceRepo < ApplicationRecord
	belongs_to :oyd_source
	belongs_to :repo
	validates :oyd_source_id, presence: true
	validates :repo_id, presence: true
end
