module Api
	module V1
		class ViewsController < ApiController
			# respond only to JSON requests
			respond_to :json
			respond_to :html, only: []
			respond_to :xml, only: []

			def show
				@views = OydView
					.joins('INNER JOIN plugin_details ON plugin_details.id = oyd_views.plugin_detail_id')
					.joins('INNER JOIN oauth_applications ON oauth_applications.id = oyd_views.plugin_id')
					.where.not("oyd_views.view_type like ?", "%mobile%")
					.where('oyd_views.id=' + params[:id].to_s)
					.select('oyd_views.id, 
						     oyd_views.plugin_id,
							 oyd_views.name, 
							 plugin_details.description, 
							 oyd_views.url, 
							 oauth_applications.uid, 
							 oauth_applications.secret, 
							 plugin_details.picture')
				render json: { id:          @views.first.id,
							   plugin_id:   @views.first.plugin_id,
							   name:        @views.first.name, 
							   description: @views.first.description,
							   url:         @views.first.url,
							   uid:         @views.first.uid,
							   secret:      @views.first.secret,
							   picture:     @views.first.picture },
					status: 200
			end

			def update
				@view = OydView.find(params[:id])
				if @view.nil?
					render json: { "error": "view not found" }, status: 404
				else
					@view.update_attributes(
						name: params[:name],
						url: params[:view_url])
					render json: { oyd_view_id: @view.id }, status: 200
				end
			end


			def mobile_index
				render json: OydView
					.joins('INNER JOIN plugin_details ON plugin_details.id = oyd_views.plugin_detail_id')
					.joins('INNER JOIN oauth_applications ON oauth_applications.id = oyd_views.plugin_id')
					.where('oauth_applications.owner_id=' + current_resource_owner.id.to_s)
					.select(:id, :name, :description, :url, :uid, :secret, :picture), 
					status: 200
			end
		end
	end
end
