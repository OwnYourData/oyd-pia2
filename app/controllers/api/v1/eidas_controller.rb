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
                redirect = params[:redirect_url].to_s

                redirect_to redirect
            end

            def token
                render json: {"token": "hello_world"}, 
                       status: 200
            end
        end
    end
end
