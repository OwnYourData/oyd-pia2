# == Schema Information
#
# Table name: oyd_installs
#
#  id           :bigint(8)        not null, primary key
#  plugin_id    :integer
#  code         :string
#  requested_ts :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'rails_helper'

RSpec.describe OydInstall, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
