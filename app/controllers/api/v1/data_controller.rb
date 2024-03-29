module Api
    module V1
        class DataController < ApiController
            include ApplicationHelper
            include UsersHelper
            include Pagy::Backend
            include PlantumlHelper

            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            after_action { pagy_headers_merge(@pagy) if @pagy }

            def index
                if doorkeeper_token.nil?
                    render json: {"error": "invalid token"},
                           status: 403
                    return
                end
                if !doorkeeper_token.application_id.nil?
                    @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                else
                    @app = Doorkeeper::Application.where(owner_id: doorkeeper_token.resource_owner_id).first rescue nil
                end

                @pagy, provision = getProvision(params, @app, "read " + params.to_json)
                if @pagy.nil?
                    render json: { "error": provision["error"] },
                           status: provision["status"]
                    return
                end
                provision_hash = Digest::SHA256.hexdigest(provision.to_json)

                if params[:id].to_s != "" && params[:p].to_s == ""
                    render json: { "error": "missing paramter specification (p=id|dri)"},
                           status: 422
                    return
                end

                if params[:f].to_s == "plain"
                    if params[:p].to_s == ""
                        retVal = []
                        provision["data"].each{ |el| retVal << el["content"] }
                    else
                        if provision == []
                            retVal = {}
                        else
                            retVal = provision["content"]
                        end
                    end

                elsif params[:f].to_s == "meta"
                    if params[:p].to_s == ""
                        retVal = []
                        provision["data"].each{ |el| retVal << el.except("content", "usage-policy", "provenance") }
                    else
                        if provision == []
                            retVal = {}
                        else
                            retVal = provision.except("content", "usage-policy", "provenance")
                        end
                    end

                elsif params[:f].to_s == "validation"
                    if params[:p].to_s == ""
                        retVal = {"data": provision["data"]}.stringify_keys
                    else
                        retVal = provision
                    end

                    response_error = false
                    response = nil
                    begin
                        response = HTTParty.post("https://blockchain.ownyourdata.eu/api/doc?hash=" + provision_hash.to_s)
                    rescue => ex
                        response_error = true
                        puts "Error: " +  ex.inspect.to_s
                    end

                    dlt_reference = ""
                    if !response_error && response.code.to_s == "200"
                        if response.parsed_response["address"] == ""
                            dlt_reference = "https://notary.ownyourdata.eu/en?hash=" + provision_hash.to_s
                        else
                            dlt_reference = {
                                "dlt": "Ethereum",
                                "address": response.parsed_response["address"],
                                "audit-proof": response.parsed_response["audit-proof"]
                            }.stringify_keys
                        end
                    end

                    retVal = {
                        "provision": provision,
                        "validation": {
                            "hash": provision_hash,
                            "dlt-reference": dlt_reference
                        }
                    }.stringify_keys

                elsif params[:f].to_s == "provis"
                    retVal = [plantuml(provision)]
                    # retVal = ["@startuml\nallowmixing\nskinparam shadowing false\nactor :Person dri-p1s...: as p1\nstate \"Activity: **create cattle**\" as a1 #palegreen\na1 : ts: 2021-01-01T01:00:00Z ref: dri-a10s...\nmap \" Entity: ** Cattle ** \" as e1 {\n  id => 10\n  dri => dri-e10s...\n}\nnode s1 #aliceblue [\nAgent: **SemCon** (Farmer)\nsemcon/sc-base:latest\nguid: id-sc1s...\n]\na1 <-up- e1 : wasGeneratedBy\na1 -> s1 : wasAssociatedWith\ns1 <-left- e1 : attributedTo\ns1 --> p1 : actedOnBehalfOf\n@enduml"]

                else # format=full
                    if provision == [] || provision == ""
                        if params[:p].to_s == ""
                            retVal = provision
                        else 
                            if provision == []
                                retVal = {}
                            else
                                retVal = provision
                            end
                        end
                    else
                        if params[:p].to_s == ""
                            retVal = {"data": provision["data"]}.stringify_keys
                        else
                            retVal = provision
                        end
                        if provision["usage-policy"].to_s != ""
                            retVal["usage-policy"] = provision["usage-policy"]
                        end
                        # retVal["provenance"] = provision["provenance"]
                    end
                end

                render json: retVal.to_json, 
                       status: 200
            end

            def write
                if doorkeeper_token.nil?
                    render json: {"error": "invalid token"},
                           status: 403
                    return
                end
                @app = Doorkeeper::Application.find(doorkeeper_token.application_id)

                begin
                    if params.include?("_json")
                        content = JSON.parse(params.to_json)["_json"]
                        other = JSON.parse(params.to_json).except("_json", "datum", "format", "controller", "action", "application")
                        if other != {}
                            content += [other]
                        end
                    else
                        content = JSON.parse(params.to_json).except("datum", "format", "controller", "action", "application")
                    end
                rescue => ex
                    render plain: "",
                           status: 422
                    return
                end
                if content.nil?
                    render json: {"error": "content missing"},
                           status: 400
                    return
                end

                if content.class == String || content.class == Hash
                    content = [content]
                end
                return_array = []

                if params["id"].to_s != "" && (params["p"].to_s == "id" || params["p"].to_s == "dri")
                    # update record
                    @item = nil
                    if params["p"].to_s == "id"
                        @item = Item.find(params["id"]) rescue nil
                    elsif params["p"].to_s == "dri"
                        @item = Item.find_by_dri(params["dri"]) rescue nil
                    end
                    if @item.nil?
                        render json: {"error": "not found"},
                               status: 404
                        return
                    end
                    complete_payload = content.first
                    payload = complete_payload.except("id", "p", "f", "dri", "schema_dri", "table_name", "mime_type")

                    repo_identifier = "default"
                    if complete_payload["table_name"].to_s != ""
                        repo_identifier = complete_payload["table_name"].to_s
                    end
                    if check_permission(repo_identifier, @app, PermType::UPDATE)
                        @repo = Repo.where(identifier: repo_identifier, 
                                           user_id: @app.owner_id).first
                        if @repo.nil?
                            # check if oyd.settings is available and re-use public_key
                            public_key = ''
                            @settings_repo = Repo.where(
                                user_id: @app.owner_id,
                                identifier: 'oyd.settings')
                            if @settings_repo.count > 0
                                public_key = @settings_repo.first.public_key
                            end
                            @repo = Repo.new(
                                user_id: @app.owner_id,
                                identifier: repo_identifier,
                                name: repo_identifier,
                                public_key: public_key)
                            @repo.save
                        end
                        @item.update_attributes(repo_id: @repo.id)

                        if payload["content"].to_s == ""
                            @item.update_attributes(value: payload.to_json)
                        else
                            @item.update_attributes(value: payload["content"].to_json)
                        end
                        if complete_payload["dri"].to_s != ""
                            @item.update_attributes(dri: complete_payload["dri"].to_s)
                        end
                        if complete_payload["schema_dri"].to_s != ""
                            @item.update_attributes(schema_dri: complete_payload["schema_dri"].to_s)
                        end
                        if complete_payload["mime_type"].to_s != ""
                            @item.update_attributes(mime_type: complete_payload["mime_type"].to_s)
                        end
                        return_array = [{ id: @item.id, status: 200 }]
                    else
                        render json: {"error": "not authorized"},
                               status: 403
                        return
                    end
                else
                    # create new record(s)
                    content.each do |item|
                        dri = nil
                        if item["dri"].to_s != ""
                            dri = item["dri"].to_s
                        end
                        schema_dri = nil
                        if item["schema_dri"].to_s != ""
                            schema_dri = item["schema_dri"].to_s
                        end
                        mime_type = "application/json"
                        if item["mime_type"].to_s != ""
                            mime_type = item["mime_type"].to_s
                        end
                        repo_identifier = "default"
                        if item["table_name"].to_s != ""
                            repo_identifier = item["table_name"].to_s
                        end
                        if item["content"].to_s != ""
                            item = item["content"]
                        end

                        if check_permission(repo_identifier, @app, PermType::WRITE)
                            @repo = Repo.where(identifier: repo_identifier, 
                                               user_id: @app.owner_id).first
                            if @repo.nil?
                                # check if oyd.settings is available and re-use public_key
                                public_key = ''
                                @settings_repo = Repo.where(
                                    user_id: @app.owner_id,
                                    identifier: 'oyd.settings')
                                if @settings_repo.count > 0
                                    public_key = @settings_repo.first.public_key
                                end
                                @repo = Repo.new(
                                    user_id: @app.owner_id,
                                    identifier: repo_identifier,
                                    name: repo_identifier,
                                    public_key: public_key)
                                @repo.save
                            end

                            if !dri.nil?
                                # check for duplicate DRI
                                user_repos = User.find(@app.owner_id).repos.pluck(:id)
                                @items = Item.where(repo_id: user_repos, dri: dri)
                                if @items.count > 0
                                    retVal = { id: @items.first.id, status: 200 }
                                else
                                    retVal = write_item(@repo, item.to_json, nil, @app.id)
                                end
                            else
                                retVal = write_item(@repo, item.to_json, nil, @app.id)
                            end
                            @item = Item.find(retVal[:id])
                            @item.update_attributes(
                                dri: dri,
                                schema_dri: schema_dri,
                                mime_type: mime_type)
                            return_array << retVal
                        end
                    end
                end
                render json: { "processed": return_array.count, 
                               "responses": return_array }, 
                       status: 200
             end

            def delete
                if doorkeeper_token.nil?
                    render json: {"error": "invalid token"},
                           status: 403
                    return
                end
                @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                user_id = @app.owner_id

                if params["p"].to_s == "id"
                    @item = Item.find(params["id"]) rescue nil
                elsif params["p"].to_s == "dri"
                    @item = Item.find_by_dri(params["id"]) rescue nil
                else
                    render json: { "error": "invalid paramenter" },
                           status: 422
                    return
                end

                if !@item.nil?
                    @repo = Repo.find(@item.repo_id)
                    if user_id == @repo.user_id
                        repo_identifier = @repo.identifier
                        if check_permission(repo_identifier, @app, PermType::DELETE)
                            retVal = { "id": @item.id }.stringify_keys
                            doc_access(PermType::DELETE, @app.id, @item.id, @repo.id, retVal.to_json)
                            @item.destroy
                            render json: retVal,
                                   status: 200
                        else
                            render json: { "error": "Permission denied" }, 
                                   status: 403
                        end
                    else
                        render json: { "error": "Permission denied" }, 
                               status: 403
                    end

                else
                    render json: { "error": "not found" },
                           status: 404
                end
            end

            def getProvision(params, app, logStr)
                @pagy, @records = getRecords(params, app)
                if @pagy.nil?
                    return @pagy, @records
                end
                if @records.nil?
                    @records = []
                end
                content = []
                if @records.count > 0
                    @records.each do |el| 
                        if el["value"].is_a? String
                            val = {"content": JSON(el["value"]).except("id")}.stringify_keys rescue {}
                        else
                            val = {"content": el["value"]}.stringify_keys
                        end
                        val["id"] = el["id"]
                        if el["dri"].to_s != ""
                            val["dri"] = el["dri"].to_s
                        end
                        if el["schema_dri"].to_s != ""
                            val["schema_dri"] = el["schema_dri"].to_s
                        end
                        if el["mime_type"].to_s != ""
                            val["mime_type"] = el["mime_type"].to_s
                        end
                        val["table_name"] = Item.find(el["id"]).repo.identifier rescue ""
                        val["created_at"] = el["created_at"].iso8601 rescue ""
                        val["updated_at"] = el["updated_at"].iso8601 rescue ""
                        content << val.stringify_keys
                    end
                end
                # content_hash = Digest::SHA256.hexdigest(content.to_json)

                cup = default_usage_policy
                if params[:p].to_s == ""
                    retVal = {
                        "data": content #,
                        # "provenance": getProvenance(content_hash, param_str, timeStart, timeEnd)
                    }.stringify_keys
                    if cup.to_s != ""
                        retVal["usage-policy"] = cup
                    end
                else
                    if content == [] || content == ""
                        retVal = content
                    else
                        retVal = content.first
                        if cup.to_s != ""
                            retVal["usage-policy"] = cup
                        end
                        # retVal["provenance"] = getProvenance(content_hash, param_str, timeStart, timeEnd)
                    end
                end

                return @pagy, retVal
            end

            def getRecords(params, app)
                page = params[:page] || 1
                retVal = nil
                # filter methods
                if params[:id] != "" && params[:p].to_s == "id"
                    # check read permission for record
                    @item = Item.find(params[:id])
                    if @item.nil?
                        @pagy = nil
                        retVal = { "error": "not found", "status": 404 }.stringify_keys
                    else
                        if @item.repo.user.id != app.user.id
                            @pagy = nil
                            retVal = { "error": "access denied", "status": 403 }.stringify_keys
                        else
                            if check_permission(Repo.find(@item.repo_id).identifier, app, PermType::READ)
                                @pagy, @records = pagy(Item.where(id: params[:id]).select(:id, :value, :dri, :schema_dri, :created_at, :updated_at, :mime_type), page: page)
                            else
                                @pagy = nil
                                retVal = { "error": "not authorized", "status": 403 }.stringify_keys
                            end
                        end
                    end
                elsif params[:id] != "" && params[:p].to_s == "dri"
                    # check read permission for each repo
                    @items = Item.where(dri: params[:id])
                    repo_ids = Repo.where(user_id: app.owner_id, id: @items.pluck(:repo_id).uniq).pluck(:id, :identifier)
                    valid_repo_ids = []
                    repo_ids.each do |repo_id, repo_identifier|
                        if check_permission(repo_identifier, app, PermType::READ)
                            valid_repo_ids << repo_id
                        end
                    end
                    if valid_repo_ids.count == 0
                        @pagy = nil
                        retVal = { "error": "not found", "status": 404 }.stringify_keys
                    else                       
                        @pagy, @records = pagy(Item.where(repo_id: valid_repo_ids, dri: params[:id]).select(:id, :value, :dri, :schema_dri, :created_at, :updated_at, :mime_type), page: page)
                    end
                elsif params[:schema_dri].to_s != ""
                    # check read permission for each repo
                    @items = Item.where(schema_dri: params[:schema_dri])
                    repo_ids = Repo.where(user_id: app.owner_id, id: @items.pluck(:repo_id).uniq).pluck(:id, :identifier)
                    valid_repo_ids = []
                    repo_ids.each do |repo_id, repo_identifier|
                        if check_permission(repo_identifier, app, PermType::READ)
                            valid_repo_ids << repo_id
                        end
                    end
                    @pagy, @records = pagy(Item.where(repo_id: valid_repo_ids, schema_dri: params[:schema_dri].to_s).select(:id, :value, :dri, :schema_dri, :created_at, :updated_at, :mime_type), page: page)
                elsif params[:table].to_s != ""
                    # check read permission for repo
                    repo_ids = Repo.where(user_id: app.owner_id, name: params[:table].to_s).pluck(:id, :identifier) rescue []
                    valid_repo_ids = []
                    repo_ids.each do |repo_id, repo_identifier|
                        if check_permission(repo_identifier, app, PermType::READ)
                            valid_repo_ids << repo_id
                        end
                    end unless repo_ids.nil?
                    @pagy, @records = pagy(Item.where(repo_id: valid_repo_ids).select(:id, :value, :dri, :schema_dri, :created_at, :updated_at, :mime_type), page: page)
                elsif params[:repo_id].to_s != ""
                    # check read permission for repo
                    if check_permission(params[:repo_id].to_s, app, PermType::READ)
                        @repo = Repo.where(user_id: app.owner_id, identifier: params[:repo_id].to_s)
                        if @repo.nil?
                            @pagy = nil
                            retVal = { "error": "not found", "status": 404 }.stringify_keys
                        else
                            if @repo.count == 0
                                @pagy = nil
                                retVal = { "error": "not found", "status": 404 }.stringify_keys
                            else
                                @pagy, @records = pagy(Item.where(repo_id: @repo.first.id).select(:id, :value, :dri, :schema_dri, :created_at, :updated_at, :mime_type), page: page)
                            end
                        end
                    else
                        @pagy = nil
                        retVal = { "error": "not authorized", "status": 403 }.stringify_keys
                    end
                else
                    # check read permission for own repos
                    repo_ids = Repo.where(user_id: app.owner_id).pluck(:id, :identifier)
                    valid_repo_ids = []
                    repo_ids.each do |repo_id, repo_identifier|
                        if check_permission(repo_identifier, app, PermType::READ)
                            valid_repo_ids << repo_id
                        end
                    end
                    if valid_repo_ids.count == 0
                        @pagy = nil
                        retVal = { "error": "not found", "status": 404 }.stringify_keys
                    else                       
                        @pagy, @records = pagy(Item.where(repo_id: valid_repo_ids).select(:id, :value, :dri, :schema_dri, :created_at, :updated_at, :mime_type), page: page)
                    end
                end
                if !@pagy.nil?
                    retVal = @records.map(&:serializable_hash) rescue []
                end

                return @pagy, retVal
            end
        end
    end
end