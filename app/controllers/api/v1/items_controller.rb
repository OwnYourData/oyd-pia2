module Api
    module V1
        class ItemsController < ApiController
            include ApplicationHelper
            require 'will_paginate/array'
            after_action only: [:index, :index_id] { set_pagination_headers(:items) rescue [] }

            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def index
                @items = []
                repo_identifier = params[:repo_identifier]
                if !doorkeeper_token.application_id.nil?
                    @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                    @repo = Repo.where(identifier: repo_identifier, 
                                       user_id: @app.owner_id).first
                else
                    @app = Doorkeeper::Application.where(owner_id: doorkeeper_token.resource_owner_id)
                    @repo = Repo.where(identifier: repo_identifier, 
                                       user_id: @app.first.owner_id).first
                end
                if @repo.nil?
                    render json: {}, status: 200
                else
                    if check_permission(@repo.identifier, @app, PermType::READ)
                        per_page_size = 2000
                        if !params[:size].nil?
                            begin
                                per_page_size = params[:size].to_i
                            rescue
                                per_page_size = 2000
                            end
                        end
                        if params[:last].nil? || !float?(params[:last].to_s)
                            @items = @repo.items
                                .order(:id)
                                .pluck(:value)
                                .paginate(page: params[:page], per_page: per_page_size)
                        else
                            @items = @repo.items
                                .order(:id)
                                .pluck(:value)
                                .last(params[:last].to_i)
                                .paginate(page: params[:page], per_page: per_page_size)
                        end
                        render json: @items, 
                               status: 200
                    else
                        render json: { "error": "Permission denied" }, 
                               status: 403
                    end
                end
            end

            def index_id
                @items = []
                repo_id = params[:id]
                if !doorkeeper_token.application_id.nil?
                    @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                    @repo = Repo.where(id: repo_id, 
                                       user_id: @app.owner_id).first
                else
                    @app = Doorkeeper::Application.where(owner_id: doorkeeper_token.resource_owner_id)
                    @repo = Repo.where(id: repo_id, 
                                       user_id: @app.first.owner_id).first
                end
                if @repo.nil?
                    render json: {}, status: 200
                else
                    if check_permission(@repo.identifier, @app, PermType::READ)
                        per_page_size = 2000
                        if !params[:size].nil?
                            begin
                                per_page_size = params[:size].to_i
                            rescue
                                per_page_size = 2000
                            end
                        end
                        @items = @repo.items
                            .order(:id)
                            .pluck(:value)
                            .paginate(page: params[:page], per_page: per_page_size)
                        render json: @items, 
                               status: 200
                    else
                        render json: { "error": "Permission denied" }, 
                               status: 403
                    end
                end
            end

            def details
                @item = Item.find(params[:id])
                if !@item.nil?
                    @repo = Repo.find(@item.repo_id)
                    # check user
                    if !doorkeeper_token.application_id.nil?
                        @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                        user_id = @app.owner_id
                    else
                        @app = Doorkeeper::Application.where(owner_id: doorkeeper_token.resource_owner_id)
                        user_id = doorkeeper_token.resource_owner_id
                    end
                    if user_id == @repo.user_id
                        repo_identifier = @repo.identifier
                        if check_permission(repo_identifier, @app, PermType::READ)
                            retVal = @item.as_json
                            retVal["repo_name"] = @item.repo.name.to_s rescue ""
                            retVal["merkle_hash"] = @item.merkle.root_hash.to_s unless @item.merkle.nil? rescue ""
                            retVal["oyd_transaction"] = @item.merkle.oyd_transaction.to_s unless @item.merkle.nil? rescue ""
                            retVal["oyd_source_pile_email"] = @item.oyd_source_pile.email.to_s unless @item.oyd_source_pile_id.nil? rescue ""
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
                    render json: { "error": "Item not found" }, 
                           status: 404
                end
            end

            def count
                    if doorkeeper_token.application_id.nil?
                        @repos = Repo.where(user_id: doorkeeper_token.resource_owner_id)
                    else
                        @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                        @repos = Repo.where(user_id: @app.owner_id)
                    end
                    count = Item.where(repo_id: @repos.pluck(:id)).count
                    render json: { "count": count },
                           status: 200
            end

            def write_item(repo, payload, pile_id)
                @item = Item.new(value: payload.to_s,
                                 repo_id: repo.id,
                                 oyd_source_pile_id: pile_id)
                if @item.save
                    val = JSON.parse(@item.value)
                    val["id"] = @item.id
                    @item.update_attributes(value: val.to_json.to_s)
                    { id: @item.id, status: 200 }
                else
                    {
                        error: @item.errors.messages.to_s,
                        status: 400 
                    }
                end
            end

            def create_item(repo, user_id, params)
                repo_identifier = params[:repo_identifier]
                if repo.nil?
                    # check if oyd.settings is available and re-use public_key
                    public_key = ''
                    @settings_repo = Repo.where(
                        user_id: user_id,
                        identifier: 'oyd.settings')
                    if @settings_repo.count > 0
                        public_key = @settings_repo.first.public_key
                    end
                    repo = Repo.new(
                        user_id: user_id,
                        identifier: repo_identifier,
                        name: repo_identifier,
                        public_key: public_key)
                    repo.save
                end
                input = params.except( *[:format, 
                                         :controller, 
                                         :action, 
                                         :repo_identifier,
                                         :item] )
                if input[:_json]
                    item_array = JSON.parse(input.to_json)['_json']
                    if(item_array.class.to_s == 'String')
                        item_array = JSON.parse(item_array)
                    end
                    return_array = []
                    return_status = 200
                    item_array.each do |item|
                        pile_id = item["oyd_source_pile_id"] rescue nil
                        if !pile_id.nil?
                            item = item.except( *[ "oyd_source_pile_id" ] )
                        end
                        retVal = write_item(repo, item.to_json.to_s, pile_id)
                        return_array << retVal
                        if retVal[:status] != 200
                            status = retVal[:status]
                        end
                    end
                    retVal = { 
                        processed: return_array.count, 
                        responses: return_array,
                        status: 200 }
                else
                    pile_id = params[:oyd_source_pile_id] rescue nil
                    payload = params.except( *[ :format, 
                                                :controller, 
                                                :action, 
                                                :repo_identifier,
                                                :oyd_source_pile_id,
                                                :item ] ).to_json.to_s
                    pile_id = JSON.parse(JSON.parse(payload.to_s.gsub("=>",":"))["value"])["oyd_source_pile_id"] rescue nil
                    if !pile_id.nil?
                        payload = payload.gsub(',\\"oyd_source_pile_id\\":' + pile_id.to_s, '')
                    end
                    write_item(repo, payload, pile_id)
                end
            end

            def create
                repo_identifier = params[:repo_identifier]
                if !doorkeeper_token.application_id.nil?
                    @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                    if check_permission(repo_identifier, @app, PermType::WRITE)
                        @repo = Repo.where(identifier: repo_identifier, 
                                           user_id: @app.owner_id).first
                        retVal = create_item(@repo, @app.owner_id, params)
                        render json: retVal.except(:status), 
                               status: retVal[:status]
                    else 
                        render json: { "error": "Permission denied" }, 
                               status: 403
                    end
                else # !doorkeeper_token.resource_owner_id.nil?
                    @app = Doorkeeper::Application.where(owner_id: doorkeeper_token.resource_owner_id)
                    if check_permission(repo_identifier, @app, PermType::WRITE)
                        @repo = Repo.where(
                            identifier: repo_identifier, 
                            user_id: doorkeeper_token.resource_owner_id).first
                        retVal = create_item(
                            @repo,
                            doorkeeper_token.resource_owner_id, 
                            params)
                        render json: retVal.except(:status), 
                               status: retVal[:status]
                    else 
                        render json: { "error": "Permission denied" }, 
                               status: 403
                    end
                end
            end

            def update
                repo_identifier = params[:repo_identifier]
                item_id = params[:id]
                @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                if check_permission(repo_identifier, @app, PermType::UPDATE)
                    @repo = Repo.where(identifier: repo_identifier, 
                                       user_id: @app.owner_id).first
                    @item = Item.find(item_id)
                    if !@item.nil?
                        if @item.repo_id == @repo.id
                            @item.update_attributes(value:
                                params.except( *[:format, 
                                                 :controller, 
                                                 :action, 
                                                 :repo_identifier, 
                                                 :item] ).to_json.to_s)
                            render json: { item_id: @item.id }, status: 200
                        else
                            render json: { "error": "Item Repo mismatch" }, 
                                   status: 401
                        end
                    else
                        render json: { "error": "Item missing" }, 
                               status: 404
                    end
                else 
                    render json: { "error": "Permission denied" }, 
                           status: 403
                end
            end

            def delete
                repo_identifier = params[:repo_identifier]
                item_id = params[:id]
                @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                if check_permission(repo_identifier, @app, PermType::DELETE)
                    @repo = Repo.where(identifier: repo_identifier, 
                                       user_id: @app.owner_id).first
                    @item = Item.find(item_id)
                    if !@item.nil?
                        if @item.repo_id == @repo.id
                            @item.destroy
                            render json: { "item_id": item_id }, 
                                   status: 200
                        else
                            render json: { "error": "Item Repo mismatch" }, 
                                   status: 401
                        end
                    else
                        render json: { "error": "Item missing" }, 
                               status: 404
                    end
                else 
                    render json: { "error": "Permission denied" }, 
                           status: 403
                end
            end

            def delete_id
                repo_id = params[:repo_id]
                item_id = params[:id]
                if !doorkeeper_token.application_id.nil?
                    @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                    @repo = Repo.find(repo_id)
                    if check_permission(@repo.identifier, @app, PermType::DELETE)
                        @item = Item.find(item_id)
                        if !@item.nil?
                            if @item.repo_id == @repo.id
                                @item.destroy
                                render json: { "item_id": item_id }, 
                                       status: 200
                            else
                                render json: { "error": "Item Repo mismatch" }, 
                                       status: 401
                            end
                        else
                            render json: { "error": "Item missing" }, 
                                   status: 404
                        end
                    else
                        render json: { "error": "Permission denied" }, 
                               status: 403
                    end
                else # !doorkeeper_token.resource_owner_id.nil?
                    @app = Doorkeeper::Application.where(owner_id: doorkeeper_token.resource_owner_id)
                    @repo = Repo.find(repo_id)
                    if check_permission(@repo.identifier, @app, PermType::DELETE)
                        @item = Item.find(item_id)
                        if !@item.nil?
                            if @item.repo_id == @repo.id
                                @item.destroy
                                render json: { "item_id": item_id }, 
                                       status: 200
                            else
                                render json: { "error": "Item Repo mismatch" }, 
                                       status: 401
                            end
                        else
                            render json: { "error": "Item missing" }, 
                                   status: 404
                        end
                    else
                        render json: { "error": "Permission denied" }, 
                               status: 403
                    end
                end
            end

            def item_merkle_update
                @item = Item.find(params[:id])
                if @item.nil?
                    render json: { "error": "Item missing" }, 
                           status: 404
                else
                    if @item.update_attributes(
                            merkle_id: params[:merkle_id],
                            oyd_hash:  params[:oyd_hash])
                        render json: { item_id: @item.id }, 
                               status: 200
                    else
                        render json: { message: @item.errors.messages }, 
                               status: 500
                    end
                end
            end

            def merkle
                mid = Merkle.where("length(oyd_transaction) < 66 or oyd_transaction IS NULL").pluck(:id)
                mid << nil
                @item = Item.where(merkle_id: mid).limit(4000)
                render json: @item.to_json, 
                       status: 200
            end

            def merkle_create
                @merkle = Merkle.new()
                if @merkle.save
                    render json: { id: @merkle.id }, 
                           status: 200
                else
                    render json: { message: @merkle.errors.messages },
                           status: 500
                end
            end

            def merkle_update
                @merkle = Merkle.find(params[:id])
                if @merkle.nil?
                    render json: { "error": "Merkle missing" }, 
                           status: 404
                else
                    if @merkle.update_attributes(
                            payload:         params[:payload],
                            merkle_tree:     params[:merkle_tree],
                            root_hash:       params[:root_hash],
                            oyd_transaction: params[:oyd_transaction])
                        render json: { merkle_id: @merkle.id }, 
                               status: 200
                    else
                        render json: { message: @merkle.errors.messages }, 
                               status: 500
                    end
                end
            end
        end
    end
end
