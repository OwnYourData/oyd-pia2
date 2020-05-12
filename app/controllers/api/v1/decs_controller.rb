module Api
	module V1
		class DecsController < ApiController

			# respond only to JSON requests
			respond_to :json
			respond_to :html, only: []
			respond_to :xml, only: []


			def register
				render json: {"did":"did:ion:abc123"},
					   status: 200
			end

			def revoke
				render plain: "",
					   status: 204
			end

		end
	end
end

