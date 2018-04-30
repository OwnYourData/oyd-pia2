module Api
	module V1
		class PluginsController < ApiController
			include AppsHelper

			# respond only to JSON requests
			respond_to :json
			respond_to :html, only: []
			respond_to :xml, only: []

			def index
				if current_resource_owner.nil?
					user_id = Doorkeeper::Application.where(
						id: doorkeeper_token.application_id).first.owner_id
				else
					user_id = current_resource_owner.id
				end
				render json: Doorkeeper::Application
						.where('owner_id=' + user_id.to_s)
						.select(:id, :identifier, :name, :uid, :secret),
					status: 200
			end

			def show
				if current_resource_owner.nil?
					render json: Doorkeeper::Application
						.where(id: params[:id])
						.select(:id, :name, :identifier, :uid, :secret),
						status: 200
				else
					render json: Doorkeeper::Application
						.where(owner_id: current_resource_owner.id, id: params[:id])
						.select(:id, :name, :identifier, :uid, :secret),
						status: 200
				end
			end

			def update
				if current_resource_owner.nil?
					if doorkeeper_token.application_id.to_i != params[:id].to_i
						render json: { "error": "Permission denied" }, 
							   status: 403
						return
					end
				else
					if !Doorkeeper::Application.where(owner_id: current_resource_owner.id).pluck(:id)
							.include?(params[:id].to_i)
						render json: { "error": "Permission denied" }, 
							   status: 403
						return
					end
				end
				@plugin = Doorkeeper::Application.find(params[:id])
				if @plugin.nil?
					render json: { "error": "plugin not found" }, 
						   status: 404
				else
					@plugin.update_attributes(name: params[:name])
					render json: { plugin_id: @plugin.id }, 
						   status: 200
				end
			end

			def current
				if !doorkeeper_token.application_id.nil?
					@plugin = Doorkeeper::Application
						.joins("INNER JOIN users ON users.id = oauth_applications.owner_id")
						.where(id: doorkeeper_token.application_id)
						.select(:id, :name, :identifier, :uid, :secret, :full_name, :email, :language)
					if !@plugin.nil?
						render json: @plugin.first,
							   status: 200
					else
						render json: { "error": "plugin not found" }, 
							   status: 404
					end
				else
					render json: { "error": "invalid request" }, 
						   status: 400
				end
			end

			def delete
				if current_resource_owner.nil?
					if doorkeeper_token.application_id.to_i != params[:id].to_i
						render json: { "error": "Permission denied" }, 
							   status: 403
						return
					end
				else
					if !Doorkeeper::Application.where(owner_id: current_resource_owner.id).pluck(:id)
							.include?(params[:id].to_i)
						render json: { "error": "Permission denied" }, 
							   status: 403
						return
					end
				end
				Doorkeeper::Application.find(params[:id]).destroy
				render json: { "plugin_id": params[:id] }, 
					   status: 200
			end

			def configure
				if current_resource_owner.nil?
					if doorkeeper_token.application_id.to_i != params[:id].to_i
						render json: { "error": "Permission denied" }, 
							   status: 403
						return
					end
				else
					if !Doorkeeper::Application.where(owner_id: current_resource_owner.id).pluck(:id)
							.include?(params[:id].to_i)
						render json: { "error": "Permission denied" }, 
							   status: 403
						return
					end
				end
				@plugin = Doorkeeper::Application.find(params[:id])
				if !@plugin.nil?
					create_tasks(@plugin, JSON.parse(@plugin.tasks.to_s), JSON.parse(params[:config].to_s))
					render json: { "plugin_id": params[:id] }, 
						   status: 200
				else
					render json: { "error": "not found" },
						   status: 404
				end

			end
		end
	end
end
