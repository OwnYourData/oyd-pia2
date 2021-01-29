module Api
	module V1
		class PermsController < ApiController
			# respond only to JSON requests
			respond_to :json
			respond_to :html, only: []
			respond_to :xml, only: []

			def index
				if !Doorkeeper::Application
						.where(id: params[:plugin_id], 
							   owner_id: current_resource_owner.id)
						.nil?
					render json: Permission
						.where(plugin_id: params[:plugin_id])
						.select(:id, :plugin_id, :repo_identifier, :perm_type, :perm_allow).to_json, 
						status: 200
				else
					render json: { "error": "Permission denied" }, status: 403
				end
			end

			def create
				if !Doorkeeper::Application
						.where(id: params[:plugin_id], 
							   owner_id: current_resource_owner.id)
						.nil?
					@perm = Permission.new(
						plugin_id: params[:plugin_id],
						repo_identifier: params[:repo_identifier],
						perm_type: params[:perm_type].to_i,
						perm_allow: params[:perm_allow])
					if @perm.save
						render json: { "perm_id": @perm.id }, status: 200
					else
						render json: { "error": @perm.errors.full_messages.first }, status: 422
					end
				else
					render json: { "error": "Permission denied" }, status: 403
				end
			end

			def update
				if !Doorkeeper::Application
						.where(id: params[:plugin_id], 
							   owner_id: current_resource_owner.id)
						.nil?
					@perm = Permission.find(params[:id])
					if @perm.nil?
						render json: { "error": "not found" }, status: 404
					else
						@perm.update_attributes(perm_allow: params[:perm_allow])
						render json: { "perm_id": @perm.id }, status: 200
					end
				else
					render json: { "error": "Permission denied" }, status: 403
				end
			end

			def delete
				if !Doorkeeper::Application
						.where(id: params[:plugin_id], 
							   owner_id: current_resource_owner.id)
						.nil?
					@perm = Permission.find(params[:id])
					if @perm.nil?
						render json: { "error": "not found" }, status: 404
					else
						@perm.destroy
						render json: { "perm_id": params[:id] }, status: 200
					end
				else
					render json: { "error": "Permission denied" }, status: 403
				end
			end

			def delete_all
				@plugin = Doorkeeper::Application.where(
								id: params[:plugin_id], 
								owner_id: current_resource_owner.id).first rescue nil
				if !@plugin.nil?
					@perm = Permission.where(plugin_id: @plugin.id, repo_identifier: params[:repo_identifier])
					if @perm.nil?
						render json: { "error": "not found" }, status: 404
					else
						perm_count = @perm.count
						@perm.destroy_all
						render json: { "count": perm_count }, status: 200
					end
				else
					render json: { "error": "Permission denied" }, status: 403
				end
			end

		end
	end
end
