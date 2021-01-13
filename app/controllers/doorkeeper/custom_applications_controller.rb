module Doorkeeper
	class CustomApplicationsController < Doorkeeper::ApplicationsController
		  def new
		puts "in new"    
		    @application = current_user.oauth_applications.new
		  end
		
	end
end