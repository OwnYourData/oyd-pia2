module Api
    module V1
        class EidasController < ApiController
            skip_before_action :doorkeeper_authorize!, only: [:create]

            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def create
                id = params[:id].to_s
                token = params[:token].to_s
                signature = params["XMLResponse"].to_s
                redirect = params[:redirect_url].to_s

                # check if token is correct and add/update signature
                @item = Item.find(id)
                if !@item.nil?
                    if @item.token == token
                        val = JSON.parse(@item.value)
                        val["eidas-signature"] = signature
                        @item.update_attributes(value: val.to_json)
                    end
                end
                redirect_to redirect
            end

            def token
                require 'securerandom'
                @item = Item.find(params[:id])
                token = SecureRandom.alphanumeric(16)
                if !@item.nil?
                    @repo = Repo.find(@item.repo_id)
                    # check user
                    if !doorkeeper_token.application_id.nil?
                        @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                        user_id = @app.owner_id
                    else
                        @app = Doorkeeper::Application.where(owner_id: doorkeeper_token.resource_owner_id)
                        user_id = doorkeeper_token.resource_owner_id
                    end
                    if user_id == @repo.user_id
                        @item.update_attributes(eidas_token: token)
                        render json: {"token": token}, 
                               status: 200
                        return
                    end
                end
                render json: {"error": "not found"}, 
                       status: 404
            end
        end
    end
end
