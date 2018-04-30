class StaticPagesController < ApplicationController
	include ApplicationHelper
	def home
		if logged_in?
			redirect_to user_path
		end
	end

	def info
	end

	def favicon
		send_file 'public/favicon.ico', type: 'image/x-icon', disposition: 'inline'
	end

	def test

	end
	
end
