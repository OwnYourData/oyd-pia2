# == Schema Information
#
# Table name: oyd_recipients
#
#  id                  :bigint(8)        not null, primary key
#  user_id             :integer
#  source_id           :integer
#  recipient_did       :string
#  fragment_identifier :string
#  fragment_array      :text
#  key                 :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
require 'rails_helper'

RSpec.describe OydRecipient, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
