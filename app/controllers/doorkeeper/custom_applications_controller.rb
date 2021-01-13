module Doorkeeper
	class CustomApplicationsController < Doorkeeper::ApplicationsController
		def new
			@application = current_user.oauth_applications.new
		end
	end
end