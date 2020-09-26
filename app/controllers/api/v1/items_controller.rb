module Api
    module V1
        class ItemsController < ApiController
            include ApplicationHelper
            require 'will_paginate/array'
            #after_action only: [:index, :index_id] { set_pagination_headers(:items) rescue [] }
            after_action Proc.new{ set_pagination_headers(:items) }, only: [:index, :index_id]

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
                        if doorkeeper_token.application_id.nil?
                            @app = @app.first
                            query_prefix = "owner"
                        end
                        if params[:last].nil? || !float?(params[:last].to_s)
                            if params[:last_days].nil? || !float?(params[:last_days].to_s)
                                @items = @repo.items
                                    .order(:id)
                                    .pluck(:value)
                                    .paginate(page: params[:page], per_page: per_page_size)
                                if params[:page].to_s != ""
                                    doc_access(PermType::READ, @app.id, nil, @repo.id)
                                else
                                    doc_access(PermType::READ, @app.id, nil, @repo.id, 
                                        [query_prefix, 
                                         "page:" + params[:page].to_s, 
                                         "size:" + per_page_size.to_s].compact.join(","))
                                end
                            else
                                @items = @repo.items
                                    .where("created_at >= ?", params[:last_days].to_i.days.ago.utc)
                                    .order(:id)
                                    .pluck(:value)
                                    .paginate(page: params[:page], per_page: per_page_size)
                                if params[:page].to_s != ""
                                    doc_access(PermType::READ, @app.id, nil, @repo.id,
                                        [query_prefix, 
                                         "last_days:" + params[:last_days].to_s].compact.join(","))
                                else
                                    doc_access(PermType::READ, @app.id, nil, @repo.id, 
                                        [query_prefix,
                                         "last_days:" + params[:last_days].to_s,
                                         "page:" + params[:page].to_s,
                                         "size:" + per_page_size.to_s].compact.join(","))
                                end
                            end
                        else
                            @items = @repo.items
                                .order(:id)
                                .pluck(:value)
                                .last(params[:last].to_i)
                                .paginate(page: params[:page], per_page: per_page_size)
                            if params[:page].to_s != ""
                                doc_access(PermType::READ, @app.id, nil, @repo.id,
                                    [query_prefix, 
                                     "last:" + params[:last].to_s].compact.join(","))
                            else
                                doc_access(PermType::READ, @app.id, nil, @repo.id, 
                                    [query_prefix, 
                                     "last:" + params[:last].to_s,
                                     "page:" + params[:page].to_s,
                                     "size:" + per_page_size.to_s].compact.join(","))
                            end
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
                        query_prefix = nil
                        if doorkeeper_token.application_id.nil?
                            @app = @app.first
                            query_prefix = "owner"
                        end
                        if params[:page].to_s != ""
                            doc_access(PermType::READ, @app.id, nil, @repo.id, query_prefix)
                        else
                            doc_access(PermType::READ, @app.id, nil, @repo.id, 
                                [query_prefix, "page:" + params[:page].to_s, "size:" + per_page_size.to_s].compact.join(","))
                        end
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

                            if doorkeeper_token.application_id.nil?
                                @app = @app.first
                                query_prefix = "owner"
                            end
                            doc_access(PermType::READ, @app.id, @item.id, nil, query_prefix)

                            retVal["access_count"] = @item.oyd_accesses.count + OydAccess.where(repo_id: @repo.id, item_id: nil).count rescue 0

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

            def dri
                if !doorkeeper_token.application_id.nil?
                    @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                    user_id = @app.owner_id
                else
                    @app = Doorkeeper::Application.where(owner_id: doorkeeper_token.resource_owner_id)
                    user_id = doorkeeper_token.resource_owner_id
                end
                user_repos = User.find(user_id).repos.pluck(:id)
                @items = Item.where(repo_id: user_repos, dri: params[:dri])
                if @items.count > 0
                    @item = @items.first
                    @repo = Repo.find(@item.repo_id)
                    # check user
                    if user_id == @repo.user_id
                        repo_identifier = @repo.identifier
                        if check_permission(repo_identifier, @app, PermType::READ)
                            retVal = @item.as_json
                            retVal["repo_name"] = @item.repo.name.to_s rescue ""
                            retVal["merkle_hash"] = @item.merkle.root_hash.to_s unless @item.merkle.nil? rescue ""
                            retVal["oyd_transaction"] = @item.merkle.oyd_transaction.to_s unless @item.merkle.nil? rescue ""
                            retVal["oyd_source_pile_email"] = @item.oyd_source_pile.email.to_s unless @item.oyd_source_pile_id.nil? rescue ""

                            if doorkeeper_token.application_id.nil?
                                @app = @app.first
                                query_prefix = "owner"
                            end
                            doc_access(PermType::READ, @app.id, @item.id, nil, query_prefix)

                            retVal["access_count"] = @item.oyd_accesses.count + OydAccess.where(repo_id: @repo.id, item_id: nil).count rescue 0

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

            def create
                if doorkeeper_token.nil?
                    render json: {"error": "invalid token"},
                           status: 403
                    return
                end
                repo_identifier = params[:repo_identifier]
                if !doorkeeper_token.application_id.nil?
                    @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                    if check_permission(repo_identifier, @app, PermType::WRITE)
                        @repo = Repo.where(identifier: repo_identifier, 
                                           user_id: @app.owner_id).first
                        retVal = create_item(@repo, @app.owner_id, params, @app.id)
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
                            params,
                            @app.first.id)
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
                            doc_access(PermType::UPDATE, @app.id, @item.id)
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
                            doc_access(PermType::DELETE, @app.id, item_id, @repo.id)
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
                                doc_access(PermType::DELETE, @app.id, item_id, repo_id)
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
                                @app = @app.first
                                query_prefix = "owner"
                                doc_access(PermType::DELETE, @app.id, item_id, repo_id, query_prefix)
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
                @item = Item.where(merkle_id: mid).limit(16380)
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
