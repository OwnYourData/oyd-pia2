module Api
	module V1
		class InstallsController < ApiController
			skip_before_action :doorkeeper_authorize!

			# respond only to JSON requests
			respond_to :json
			respond_to :html, only: []
			respond_to :xml, only: []

			def show
				@records = OydInstall.where(code: params[:key].to_s)
				if !@records.nil? && @records.count == 1
					@record = @records.first
					app_key = @record.oauth_application.uid
					app_secret = @record.oauth_application.secret
					@record.destroy
					render json: {"key": app_key,
								  "secret": app_secret},
						   status: 200
				else
					render json: {"error":"not found"},
						   status: 404
				end
			end
		end
	end
end