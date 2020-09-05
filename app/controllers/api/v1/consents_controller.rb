module Api
	module V1
		class ConsentsController < ApiController

			# respond only to JSON requests
			respond_to :json
			respond_to :html, only: []
			respond_to :xml, only: []

            include ApplicationHelper

			# expected input for POST /api/consent
			# {
			#     phone_number: wizardData.profile.phone,
			#     payload: any information provided by the user
			# }
			def create
                did = params[:consent]["did"].to_s
                @user = User.find_by_did(did)
                if @user.nil? || did == ""
                    render json: {"error": "DID not found"},
                           status: 404
                    return
                end
                @repo = @user.repos.where(identifier: "oyd.consent").first rescue nil
                my_params = params["consent"]
                my_params[:repo_identifier] = "oyd.consent"

                plugin_id = @user.oauth_applications.where(identifier: "oyd.dec112").first.id rescue nil

                if plugin_id.nil?
                    render json: {"error": "plugin not found"},
                           status: 404
                else
                    retVal = create_item(@repo, @user.id, my_params, plugin_id)
                    render json: retVal.except(:status), 
                           status: retVal[:status]
                end
            end

            def index
                render plain: "",
                       status: 204
            end

            def show
                render plain: "",
                       status: 204
            end

            def update
                render plain: "",
                       status: 204
            end

            def delete
                render plain: "",
                       status: 204
            end

		end
	end
end

