# == Schema Information
#
# Table name: weekly_news
#
#  id         :bigint(8)        not null, primary key
#  week       :string
#  news_text  :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe WeeklyNews, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
