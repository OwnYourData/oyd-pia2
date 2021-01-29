module Api
    module V1
        class ReposController < ApiController
            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            include ApplicationHelper

            def index
                if doorkeeper_token.application_id.nil?
                    user_id = current_resource_owner.id
                else
                    @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                    user_id = @app.owner_id
                end
                @user = User.find(user_id)
                @repos = @user.repos
                retVal = []
                @repos.each do |repo|
                    begin
                        if repo.identifier.match?(/#{Permission.where(
                                    plugin_id: @user.oauth_applications.pluck(:id),
                                    perm_type: PermType::READ
                                ).pluck(:repo_identifier).join('|')}/)
                            retVal << { "id": repo.id,
                                        "name": repo.name, 
                                        "count": "?",
                                        "identifier": repo.identifier } #repo.items.count }
                        end
                    rescue

                    end
                end unless @repos.nil?
                render json: retVal, status: 200

            end

            def show
                if doorkeeper_token.application_id.nil?
                    user_id = current_resource_owner.id
                else
                    @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                    user_id = @app.owner_id
                end
                @repo = Repo.where(
                    id: params[:id], 
                    user_id: user_id)
                if (@repo.nil? or @repo.count == 0)
                    render json: { "error": "repo not found" }, 
                           status: 404
                else
                    render json: @repo.first,
                           status: 200
                end
            end

            def show_identifier
                if doorkeeper_token.application_id.nil?
                    user_id = current_resource_owner.id
                else
                    @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                    user_id = @app.owner_id
                end
                @repo = Repo.where(
                    identifier: params[:identifier], 
                    user_id: user_id)
                if (@repo.nil? or @repo.count == 0)
                    render json: { "error": "repo not found" }, 
                           status: 404
                else
                    render json: @repo.first.attributes.merge("items": @repo.first.items.count).stringify_keys,
                           status: 200
                end
            end

            def delete
                if !doorkeeper_token.application_id.nil?
                    @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                    @repo = Repo.where(id: params[:id],
                                       user_id: @app.owner_id)
                else
                    @app = Doorkeeper::Application.where(owner_id: doorkeeper_token.resource_owner_id)
                    @repo = Repo.where(id: params[:id], 
                                       user_id: @app.first.owner_id)
                end
                if (@repo.nil? or @repo.count == 0)
                    render json: { "error": "repo not found" }, 
                           status: 404
                else
                    @repo.destroy_all
                    render json: { "repo_id": params[:id] },
                           status: 200
                end
            end

            def items
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
                        if params[:last].nil? || !float?(params[:last].to_s)
                            @items = @repo.items
                                .order(:id)
                                .paginate(page: params[:page], per_page: per_page_size)
                        else
                            @items = @repo.items
                                .order(:id)
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

            def count
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
                        render json: { "id": @repo.id,
                                       "count": @repo.items.count },
                               status: 200
                    else
                        render json: { "error": "Permission denied" }, 
                               status: 403
                    end
                end
            end

            def pub_key
                repo_identifier = params[:id]
                if !doorkeeper_token.application_id.nil?
                    if repo_identifier.match?(/#{Permission.where(
                                plugin_id: doorkeeper_token.application_id, 
                                perm_type: PermType::WRITE
                            ).pluck(:repo_identifier).join('|')}/)
                        @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                        @repo = Repo.where(user_id: @app.owner_id,
                                              identifier: repo_identifier)
                        if @repo.count == 0
                            @repo = Repo.where(user_id: @app.owner_id,
                                                  identifier: 'oyd.settings')
                        end
                        if @repo.count > 0
                            render json: @repo.select(:id, :identifier, :public_key).first,
                                   status: 200
                        else
                            render json: { "error": "repo not found" },
                                   status: 404
                        end
                    else
                        render json: { "error": "Permission denied" }, 
                               status: 403
                    end
                else # !doorkeeper_token.resource_owner_id.nil?
                    @repo = Repo.where(user_id: current_resource_owner.id,
                                          identifier: repo_identifier)
                    if @repo.count == 0
                        @repo = Repo.where(user_id: current_resource_owner.id,
                                              identifier: 'oyd.settings')
                    end
                    if @repo.count > 0
                        render json: @repo.select(:id, :identifier, :public_key).first,
                               status: 200
                    else
                        render json: { "error": "repo not found" },
                               status: 404
                    end
                end
            end

            def apps # who is using this function?! - delete?!
                @repos = Repo.where(user_id: current_resource_owner.id)
                retVal = []
                @repos.each do |repo|
                    if repo.identifier.match?(/#{Permission.where(
                                plugin_id: params[:plugin_id], 
                                perm_type: PermType::READ
                            ).pluck(:repo_identifier).join('|')}/)
                        retVal << { "id": repo.id,
                                    "name": repo.name, 
                                    "count": repo.items.count }
                    end
                end
                render json: retVal, status: 200
            end
        end
    end
end