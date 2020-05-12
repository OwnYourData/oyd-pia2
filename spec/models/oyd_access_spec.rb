# == Schema Information
#
# Table name: oyd_accesses
#
#  id           :bigint(8)        not null, primary key
#  timestamp    :integer
#  operation    :integer
#  oyd_hash     :string
#  merkle_id    :integer
#  plugin_id    :integer
#  item_id      :integer
#  user_id      :integer
#  previous_id  :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  repo_id      :integer
#  query_params :string
#

require 'rails_helper'

RSpec.describe OydAccess, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
