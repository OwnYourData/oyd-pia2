# == Schema Information
#
# Table name: oyd_relations
#
#  id         :bigint(8)        not null, primary key
#  source_id  :integer
#  target_id  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_oyd_relations_on_source_id  (source_id)
#  index_oyd_relations_on_target_id  (target_id)
#
class OydRelation < ApplicationRecord
end
