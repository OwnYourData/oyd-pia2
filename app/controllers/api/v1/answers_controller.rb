module Api
	module V1
		class AnswersController < ApiController
			# respond only to JSON requests
			respond_to :json
			respond_to :html, only: []
			respond_to :xml, only: []

			def index
				@answers = OydAnswer.where(plugin_id: 
					Doorkeeper::Application.find(doorkeeper_token.application_id)
						.user.oauth_applications.pluck(:id))
				if @answers.nil?
					render json: {}, 
						   status: 200
				else
					render json: @answers.select(:id, 
												 :name, 
												 :short,
												 :identifier, 
												 :plugin_id, 
												 :category, 
												 :info_url, 
												 :repos, 
												 :answer_order, 
												 :answer_view, 
												 :answer_logic),
						   status: 200
				end
			end

			def show
				@oyd_answer = OydAnswer.find(params[:id])
				render json: @oyd_answer.attributes, 
					   status: 200
			end
		end
	end
end