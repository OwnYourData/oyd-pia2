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

class OydAccess < ApplicationRecord

    filterrific(
        default_filter_params: { sorted_by: "created_at_desc" },
        available_filters: [
            :sorted_by,
            :search_query,
            :with_plugin_id,
            :with_created_at_gte,
        ],
    )

	belongs_to :item, optional: true
    belongs_to :oauth_application, class_name: 'Doorkeeper::Application', foreign_key: 'plugin_id', optional: true
    belongs_to :user
    validates :user_id, presence: true

    scope :search_query, ->(query) {
        # Filters items whose hash or item_id matches the query
        return nil  if query.blank?

        terms = query.downcase.split(/\s+/)
        terms = terms.map { |e|
            (e.tr("*", "%") + "%").gsub(/%+/, "%")
        }
        num_or_conds = 2
        where(
            terms.map { |_term|
               "(LOWER(oyd_accesses.oyd_hash) LIKE ? OR oyd_accesses.item_id LIKE ?)"
            }.join(" AND "),
            *terms.map { |e| [e] * num_or_conds }.flatten,
        )        
    }

    scope :sorted_by, ->(sort_option) {
        # Sorts items by sort_key
        direction = /desc$/.match?(sort_option) ? "desc" : "asc"
        case sort_option.to_s
        when /^created_at_/
            order("oyd_accesses.created_at #{direction}")
        when /^plugin_/
            order("oyd_accesses.plugin_id #{direction}, oyd_accesses.created_at #{direction}")
        when /^operation_/
            order("oyd_accesses.operation #{direction}, oyd_accesses.created_at #{direction}")
        else
            raise(ArgumentError, "Invalid sort option: #{sort_option.inspect}")
        end
    }
    scope :with_plugin_id, ->(plugin_ids) {
        # Filters items with any of the given plugin_ids
        where(plugin_id: [*plugin_ids])
        
    }
    scope :with_created_at_gte, ->(ref_date) {
        where("oyd_accesses.created_at >= ?", ref_date)
    }

    # This method provides select options for the `sorted_by` filter select input.
    # It is called in the controller as part of `initialize_filterrific`.
    def self.options_for_sorted_by
    [
        ["Timestamp (newest first)", "created_at_desc"],
        ["Timestamp (oldest first)", "created_at_asc"],
        ["Plugin", "plugin_id_asc"]
    ]
    end
end
