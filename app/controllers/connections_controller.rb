class ConnectionsController < ApplicationController
    skip_before_action :verify_authenticity_token
    include ApplicationHelper
    def create
        puts "Connections ==="
        puts params.to_json
        puts "---------------"
        record = params["connection"]
        @connect = Item.find(record[:id])
        @user = @connect.repo.user
        user_id = @user.id

        repo_pubkey = ""
        @settings_repo = Repo.where(user_id: @user.id, identifier: 'oyd.settings')
        if @settings_repo.count > 0
            repo_pubkey = @settings_repo.first.public_key
        end
        @repo = Repo.where(user_id: user_id, identifier: "oyd.covid19credential").first rescue nil
        if @repo.nil?
            @repo = Repo.new(
                        user_id: user_id, 
                        name: "Covid19 Credentials",
                        identifier: "oyd.covid19credential",
                        public_key: repo_pubkey)
            @repo.save
        end
        repo_id = @repo.id

        schema_dri = record[:schema_dri].to_s
        provenance = record[:provenance]
# Add
# map " Entity: ** Record ** " as e2 {
#   id => 1992345
#   dri => zQmNaBhNAX7v7BDBnyewdmAjGwfUaGz4NNRhaDwAVhLG2UC
# }
# state "Activity: **copy Record**" as a3 #palegreen
# a3 : ts: 2022-04-30T23:08:08Z\nref: 0377967fa97a075153dabf7b32367f9d3bdd03f8b44cd3718e79634e165f9455
# node s2 #aliceblue [
# Agent: **DataVault**
# image: oydeu/oyd-pia2
# guid: 6f0ce9aa-b83e-4eab-9043-6d7bfd550d19
# ]
# s2 <- e2 : attributedTo
# a3 <- e2 : wasGeneratedBy
# a3 -down-> s2 : wasAssociatedWith
# a3 -up-> e1 : used


puts "Value:"
puts record[:value].to_json
puts "..."
puts "Repo_id: " + repo_id.to_s
puts "Provenance: " + provenance.to_s
puts "schema_dri: " + schema_dri

        @item = Item.new(
            value: record[:value].to_json,
            repo_id: repo_id,
            provenance: provenance,
            schema_dri: schema_dri)
        @item.save

        # update Provenance
        provenance = provenance.sub("@enduml","\n")
        provenance += 'map " Entity: ** Record ** " as e2 {' + "\n"
        provenance += "  id => " + @item.id.to_s + "\n"
        provenance += "  dri => " + Oydid.hash(Oydid.canonical(JSON.parse(@item.value))) + "\n"
        provenance += "}\n"
        provenance += 'state "Activity: **copy Record**" as a3 #palegreen' + "\n"
        provenance += "a3 : ts: " + @item.created_at.utc.iso8601 + "\n"
        provenance += "node s2 #aliceblue [\n"
        provenance += "  Agent: **DataVault**\n"
        provenance += "  image: oydeu/oyd-pia2\n"
        provenance += "]\n"
        provenance += "s2 <- e2 : attributedTo\n"
        provenance += "a3 <- e2 : wasGeneratedBy\n"
        provenance += "a3 -down-> s2 : wasAssociatedWith\n"
        provenance += "a3 -up-> e1 : used\n"
        provenance += "@enduml"
        @item.update_attributes(provenance: provenance)

        # create Relation
        OydRelation.new(source_id: @item.id, target_id: @connect.id).save

        render json: {},
               status: 200

    end
end
