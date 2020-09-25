module Api
    module V1
        class DataController < ApiController
            include ApplicationHelper
            require 'will_paginate'

            # after_action only: [:read] { set_pagination_headers(:items) }
            #after_action Proc.new{ set_pagination_headers(:items) } unless :items.nil?, only: [:read]

            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def read
                if doorkeeper_token.nil?
                    render json: {"error": "invalid token"},
                           status: 403
                    return
                end
                @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                user_id = @app.owner_id
                @items = {}
                if !params[:id].nil? || !params[:dri].nil?
                    if !params[:id].nil?
                        @item = Item.find(params[:id])
                    else
                        @item = Item.find_by_dri(params[:dri])
                    end
                    if !@item.nil?
                        @repo = Repo.find(@item.repo_id)
                        if user_id == @repo.user_id
                            repo_identifier = @repo.identifier
                            if check_permission(repo_identifier, @app, PermType::READ)
                                retVal = @item.value.as_json
                                doc_access(PermType::READ, @app.id, @item.id, nil, "")
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
                elsif !params[:schema].nil?
                    user_repos = @app.user.repos.pluck(:id)
                    @items = Item.where(repo_id: user_repos, schema_dri: params[:schema])
                    if @items.count > 0
                        retVal = []
                        @items.each do |item|
                            @repo = Repo.find(item.repo_id)
                            if user_id == @repo.user_id
                                repo_identifier = @repo.identifier
                                if check_permission(repo_identifier, @app, PermType::READ)
                                    if item.mime_type == "application/json"
                                        retVal << JSON.parse(item.value)
                                    else
                                        retVal << item.value.to_s
                                    end
                                    doc_access(PermType::READ, @app.id, item.id, nil, "")
                                end
                            end
                        end
                        render json: retVal,
                               status: 200
                    else
                        render json: { "error": "not found" },
                               status: 404
                    end
                else
                    render json: { "error": "missing request parameter" },
                           status: 500
                end
            end

            def write
                if doorkeeper_token.nil?
                    render json: {"error": "invalid token"},
                           status: 403
                    return
                end
                @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                content = params["content"] rescue nil
                if content.nil?
                    render json: {"error": "content missing"},
                           status: 400
                    return
                end
                dri = params["dri"] rescue nil
                schema_dri = params["schema_dri"] rescue nil
                mime_type = params["mime_type"] rescue "application/json"                
                repo_identifier = params["table_name"].to_s rescue "default"
                params = content
                if repo_identifier.to_s == ""
                    repo_identifier = "default"
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
                            retVal = create_item(@repo, @app.owner_id, params, @app.id)
                        end
                    else
                        retVal = create_item(@repo, @app.owner_id, params, @app.id)
                    end
                    @item = Item.find(retVal[:id])
                    @item.update_attributes(
                        dri: dri,
                        schema_dri: schema_dri,
                        mime_type: mime_type)
                    render json: retVal.except(:status), 
                           status: retVal[:status]
                else 
                    render json: { "error": "Permission denied" }, 
                           status: 403
                end
            end

        end
    end
end