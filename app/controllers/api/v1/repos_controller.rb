module Api
	module V1
		class ReposController < ApiController
			# respond only to JSON requests
			respond_to :json
			respond_to :html, only: []
			respond_to :xml, only: []

			def index
				@user = User.find(current_resource_owner.id)
				@repos = @user.repos
				retVal = []
				@repos.each do |repo|
					if repo.identifier.match?(/#{Permission.where(
								plugin_id: @user.oauth_applications.pluck(:id),
								perm_type: PermType::READ
							).pluck(:repo_identifier).join('|')}/)
						retVal << { "id": repo.id,
						            "name": repo.name, 
						            "count": repo.items.count }
					end
				end unless @repos.nil?
				render json: retVal, status: 200

			end

			def show
				@repo = Repo.where(
					id: params[:id], 
					user_id: current_resource_owner.id)
				if @repo.nil?
					render json: { "error": "repo not found" }, 
						   status: 404
				else
					render json: @repo.first,
						   status: 200
				end
			end

			def delete
				@repo = Repo.where(
					id: params[:id], 
					user_id: current_resource_owner.id)
				if @repo.nil?
					render json: { "error": "repo not found" }, 
						   status: 404
				else
					@repo.destroy_all
					render json: { "repo_id": params[:id] },
						   status: 200
				end
			end

			def items
				@repo = Repo.where(
					id: params[:id], 
					user_id: current_resource_owner.id)
				if @repo.nil?
					render json: { "error": "repo not found" }, 
						   status: 404
				else
					@items = Item.where(repo_id: @repo.first.id)
					render json: @items,
						   status: 200
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

			def apps
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