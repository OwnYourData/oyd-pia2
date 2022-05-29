module Api
    module V1
        class QrsController < ApiController

            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            include ApplicationHelper
            include PluginsHelper

            def read
                did = params[:did].to_s rescue ""

                @user = Doorkeeper::Application.find(doorkeeper_token.application_id).user
                # @user = User.find(current_user["id"])

                didDoc = Oydid.read(did, {})
                services = didDoc.first["doc"]["doc"]
                up_endpoint = services["usagePolicy"]
                info_endpoint = services["info"]
                connect_endpoint = services["connect"]
                soya_dri = services["schemaDri"]
                infos = HTTParty.get(info_endpoint).parsed_response rescue {}

                usage_policy_user = {}
                @repo = Repo.where(user_id: @user.id, identifier: "default").first
                @configItems = Item.where(repo_id: @repo.id, schema_dri: CONFIG_ITEM_DRI)
                @configItems.each do |i|
                    begin
                        if JSON.parse(i.value)["key"] == "usage_policy"
                            usage_policy_user = JSON.parse(i.value)["value"]
                        end
                    rescue
                    end
                end unless @configItems.nil?
                if usage_policy_user.is_a?(String)
                    usage_policy_user = JSON.parse(usage_policy_user) rescue {}
                end
                usage_policy_external = HTTParty.get(up_endpoint).parsed_response rescue {}

                dpv_matching = {
                    "data-subject": {
                        "@context": {
                          "@version": 1.1,
                          "@vocab": "https://soya.data-container.net/UsagePolicy/",
                          "dpv": "http://www.w3.org/ns/dpv#",
                          "dpv-soya": "https://w3id.org/soya/dpv#",
                          "dpv:hasPersonalDataCategory": { "@type": "@id" },
                          "dpv:hasProcessing": { "@type": "@id" },
                          "dpv:hasPurpose": { "@type": "@id" },
                          "dpv:hasExpiryTime": { "@type": "http://www.w3.org/2001/XMLSchema#dateTime" }
                        },
                        "@graph": [ usage_policy_user ] },
                    "data-controller": {
                        "@context": {
                          "@version": 1.1,
                          "@vocab": "https://soya.data-container.net/UsagePolicy/",
                          "dpv": "http://www.w3.org/ns/dpv#",
                          "dpv-soya": "https://w3id.org/soya/dpv#",
                          "dpv:hasPersonalDataCategory": { "@type": "@id" },
                          "dpv:hasProcessing": { "@type": "@id" },
                          "dpv:hasPurpose": { "@type": "@id" },
                          "dpv:hasExpiryTime": { "@type": "http://www.w3.org/2001/XMLSchema#dateTime" }
                        },
                        "@graph": [ usage_policy_external ] }
                }
                dpv_matching_url = "https://dpv.ownyourdata.eu/api/validate/usagepolicy"
                # query service if policies match
                response = HTTParty.post(dpv_matching_url, 
                    headers: { 'Content-Type' => 'application/json',
                               :Accept => "*/*" },
                    body: dpv_matching.to_json,
                    format: :plain)
                up_compliance = true
                up_error = "Usage Policies are compatible"
                if response.code != 200
                    up_compliance = false
                    up_error = response.parsed_response
                end

                repo_pubkey = ""
                @settings_repo = Repo.where(user_id: @user.id, identifier: 'oyd.settings')
                if @settings_repo.count > 0
                    repo_pubkey = @settings_repo.first.public_key
                end

                @repo = Repo.where(user_id: @user.id, identifier: "oyd.connect").first rescue nil
                if @repo.nil?
                    @repo = Repo.new(
                                user_id: @user.id, 
                                name: "Connection Records",
                                identifier: "oyd.connect",
                                public_key: repo_pubkey)
                    @repo.save
                end
                if up_compliance
                    up_match = "compliant"
                else
                    up_match = "Error: '" + up_error + "'"
                end
                connect_rec = {
                    "timestamp": Time.now.getutc.to_i,
                    "did": did,
                    "DidDocument": didDoc,
                    "UsagePolicyExternal": usage_policy_external,
                    "UsagePolicySelf": usage_policy_user,
                    "UsagePolicyMatch": up_match,
                    "externalTitle": infos["title"].to_s,
                    "externalDescription": infos["description"].to_s,
                    "externalContact": infos["contact"].to_s,
                    "externalDataRequest": infos["fields"].to_s,
                    "externalSeviceEndpoint": connect_endpoint,
                    "status": "created",
                    "repo_identifier": "oyd.connect"
                }.stringify_keys rescue {}
                plugin_id = @user.oauth_applications.where(identifier: "dev.unterholzer.ownyourdata.form").first.id rescue nil
                new_item = create_item(@repo, @user.id, connect_rec, plugin_id)

                personalData = usage_policy_external["dpv:hasPersonalData"].join(", ") rescue usage_policy_external["dpv:hasPersonalData"].to_s
                purpose = usage_policy_external["dpv:hasPurpose"].join(", ") rescue usage_policy_external["dpv:hasPurpose"].to_s
                processing = usage_policy_external["dpv:hasProcessing"].join(", ") rescue usage_policy_external["dpv:hasProcessing"].to_s
                recipient = usage_policy_external["dpv:hasRecipient"].join(", ") rescue usage_policy_external["dpv:hasRecipient"].to_s
                if recipient.to_s == "" or recipient.to_s == "Recipient"
                    recipient = "not specified"
                end
                location = usage_policy_external["dpv:hasLocation"].join(", ") rescue usage_policy_external["dpv:hasLocation"].to_s
                if location.to_s == "" or location.to_s == "Location"
                    location = "not specified"
                end
                expiryTime = DateTime.parse(usage_policy_external["dpv:hasExpiryTime"].to_s).to_formatted_s(:rfc822)
                technicalMeasure = usage_policy_external["dpv:hasTechnicalMeasure"].join(", ") rescue usage_policy_external["dpv:hasTechnicalMeasure"].to_s
                if technicalMeasure.to_s == ""
                    technicalMeasure = "not specified"
                end
                organisationalMeasure = usage_policy_external["dpv:hasOrganisationalMeasure"].join(", ") rescue usage_policy_external["dpv:hasOrganisationalMeasure"].to_s
                if organisationalMeasure.to_s == ""
                    organisationalMeasure = "not specified"
                end
                legalBasis = usage_policy_external["dpv:hasLegalBasis"].join(", ") rescue usage_policy_external["dpv:hasLegalBasis"].to_s
                risk = usage_policy_external["dpv:hasRisk"].join(", ") rescue usage_policy_external["dpv:hasRisk"].to_s
                if risk.to_s == ""
                    risk = "not specified"
                end

                retVal = {
                    "id": new_item[:id],
                    "content": { 
                      "name": {
                        "title": infos["title"].to_s,
                        "description": infos["description"].to_s,
                        "contact": infos["contact"].to_s,
                        "dataRequest": infos["fields"].join(" ").to_s,
                      },
                      "usage_policy": {
                        "user_compatible": up_compliance,
                        "match_error": up_error,
                        "personalData": personalData.gsub("dpv:",""),
                        "purpose": purpose.gsub("dpv:",""),
                        "processing": processing.gsub("dpv:",""),
                        "recipient": recipient.gsub("dpv:",""),
                        "location": location.gsub("dpv:",""),
                        "expiryTime": expiryTime,
                        "technicalMeasure": technicalMeasure.gsub("dpv:",""),
                        "organisationalMeasure": organisationalMeasure.gsub("dpv:",""),
                        "legalBasis": legalBasis.gsub("dpv:",""),
                        "risk": risk
                      },
                      "endpoints": {
                        "usagepolicy_endpoint": up_endpoint,
                        "info_endpoint": info_endpoint,
                        "apply_endpoint": connect_endpoint
                      }
                    },
                    "schema_dri": soya_dri || CONNECTION_INFO_DRI
                }

puts "--- retval ---"
puts retVal.to_json
puts "--------------"

                render json: retVal,
                       status: 200
            end

            def qr_connect
                action = params["qr"]["action"].to_s rescue ""
                id = params["qr"]["id"].to_s rescue ""
                if action.to_s == "send"
                    @item = Item.find(id)
                    @user = @item.repo.user
                    value = JSON.parse(@item.value)
                    connect_endpoint = value["externalSeviceEndpoint"]

                    @repo = Repo.where(user_id: @user.id, identifier: "default").first
                    @personal = Item.where(schema_dri: PERSONAL_DATA_DRI, repo_id: @repo.id).first
                    record = JSON.parse(@personal.value) rescue {}
                    record["oydDatavault"] = "https://data-vault.eu/connect"
                    record["oydToken"] = SecureRandom.uuid
                    record["oydId"] = id
                    value["token"] = record["oydToken"]
                    @item.update_attributes(value: value.to_json)
                    response = HTTParty.post(
                        connect_endpoint, 
                        headers: { 'Content-Type' => 'application/json' },
                        body: record.to_json )
                    if response.code == 200
                        retVal = {"message": "Data sent successfully!"}
                    else
                        retVal = {"message": "cannot reach: " + connect_endpoint}
                    end
                else
                    retVal = {"message": "no data was sent"}
                end
                render json: retVal,
                       stauts: 200
            end
        end
    end
end

