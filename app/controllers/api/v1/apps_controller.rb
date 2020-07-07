module Api
	module V1
		class AppsController < ApiController
			include PluginsHelper

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
				render json: OydView
						.joins('INNER JOIN plugin_details ON plugin_details.id = oyd_views.plugin_detail_id')
						.joins('INNER JOIN oauth_applications ON oauth_applications.id = oyd_views.plugin_id')
						.where.not("oyd_views.view_type like ?", "%mobile%")
						.where('oauth_applications.owner_id=' + user_id.to_s)
						.select(:id, :plugin_id, :name, :uid, :secret, :confidential, :identifier, :url, :view_type, :picture, "plugin_details.description as description"), 
					status: 200
			end

			def show
				if current_resource_owner.nil?
					@app = Doorkeeper::Application.where(id: params[:id]).first rescue nil
					# render json: Doorkeeper::Application
					# 	.where(id: params[:id])
					# 	.select(:id, :name, :identifier, :uid, :secret, :confidential),
					# 	status: 200
				else
					@app = Doorkeeper::Application.where(owner_id: current_resource_owner.id, id: params[:id]).first rescue nil
					# render json: Doorkeeper::Application
					# 	.where(owner_id: current_resource_owner.id, id: params[:id])
					# 	.select(:id, :name, :identifier, :uid, :secret, :confidential),
					# 	status: 200
				end
				if @app.nil?
					render json: {"error": "not found"},
						   status: 404
				else
					render json: [{ id: @app.id,
						           name: @app.name,
						           identifier: @app.identifier,
						           uid: @app. uid,
						           secret: @app.secret }],
						   status: 200
				end
			end

			def update
				@view = OydView.find(params[:oyd_view_id])
				if @view.nil?
					render json: { "error": "view not found" }, status: 404
				else
					@view.update_attributes(
						name: params[:name],
						url: params[:app_url])
					render json: { oyd_view_id: @view.id }, status: 200
				end
			end

			def destroy
				@view = OydView.find(params[:oyd_view_id])
				if @view.nil?
					render json: { "error": "view not found" }, status: 404
				else
					plugin_id = @view.plugin_id
					@view.destroy
					if OydView.where(plugin_id: plugin_id).count == 0
						@plugin = Doorkeeper::Application.find(plugin_id)
						if @plugin.nil?
							render json: { "error": "plugin not found (view deleted)" }, status: 404
						else
							@plugin.destroy
							render json: { plugin_id: plugin_id }, status: 200
						end
					else
						render json: { oyd_view_id: params[:plugin_id] }, status: 200
					end
				end
			end
		end
	end
end
