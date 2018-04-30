module Api
	module V1
		class LogsController < ApiController
			# respond only to JSON requests
			respond_to :json
			respond_to :html, only: []
			respond_to :xml, only: []

			def index
				@tasks = Log.all
				render json: @logs.to_json, status: 200

			end

			def create
				if !doorkeeper_token.application_id.nil?
					@app = Doorkeeper::Application.find(doorkeeper_token.application_id)
					plugin_id = doorkeeper_token.application_id
					user_id = @app.owner_id
				end
				if !doorkeeper_token.resource_owner_id.nil?
					plugin_id = nil
					user_id = doorkeeper_token.resource_owner_id
				end
				@log = Log.new(
					user_id: user_id,
					plugin_id: plugin_id,
					identifier: params[:identifier].to_s,
					message: params[:log].to_s)
				@log.save
				render json: { log_id: @log.id }, status: 200
			end

		end
	end
end
