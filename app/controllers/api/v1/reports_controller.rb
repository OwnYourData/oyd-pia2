module Api
	module V1
		class ReportsController < ApiController
			# respond only to JSON requests
			respond_to :json
			respond_to :html, only: []
			respond_to :xml, only: []

			def index
				@reports = OydReport.where(plugin_id: 
					Doorkeeper::Application.find(doorkeeper_token.application_id)
						.user.oauth_applications.pluck(:id))
				if @reports.nil?
					render json: {}, 
						   status: 200
				else
					render json: @reports.select(:id, :name, :identifier, :plugin_id, :data_prep, :data_snippet, :current, :report_view, :answer_view, :answer_logic),
						   status: 200
				end
			end

			def update
				@oyd_report = OydReport.find(params[:id])
				@oyd_report.update_attributes(current: params[:current])
				render json: { report_id: @oyd_report.id }, status: 200
			end
		end
	end
end