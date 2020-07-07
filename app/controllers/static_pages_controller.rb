class StaticPagesController < ApplicationController
	include ApplicationHelper
	def home
		if logged_in?
			redirect_to user_path
		end
	end

	def info
	end

	def gmaps
	end

	def phone
	end

	def code
		@phone_number = params[:phone_number].to_s
		if request.post?
			redirect_to phone_code_path(phone_number: @phone_number)
		end
		puts "send code to " + @phone_number

	end

	def favicon
		send_file 'public/favicon.ico', type: 'image/x-icon', disposition: 'inline'
	end

	def test
	end
	
end
