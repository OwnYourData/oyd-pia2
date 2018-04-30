module SessionsHelper
	def log_in(token)
		session[:token] = token
	end

	def current_user
        user_info_url = getServerUrl() + "/api/users/show"
        if session[:token].nil?
        	@current_user = nil
        else
	        begin
	            response = HTTParty.get(user_info_url, 
					headers: { "Authorization": "Bearer " + session[:token] })
	        rescue => ex
	            response = nil
	        end
	        if response.nil? or response.code != 200
	        	@current_user = nil
	        else
	        	@current_user = response.parsed_response
	        end
		end
	end

	def logged_in?
		!current_user.nil?
	end

	def log_out
		session.delete(:token)
		@current_user = nil
	end

	private 

    def logged_in_user
      unless logged_in?
        flash[:danger] = oyd_backend_translate("Please log in.", params[:locale])
        redirect_to login_url
      end
    end


end
