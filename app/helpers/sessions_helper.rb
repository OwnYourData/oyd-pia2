module SessionsHelper
	def log_in(token)
		session[:token] = token
	end

	def remember(user)
		remember_token = SecureRandom.urlsafe_base64
		remember_url = getServerUrl() + "/api/users/do_remember"
    	begin
	        response = HTTParty.post(remember_url, 
				headers: { "Authorization": "Bearer " + session[:token],
						   "Content-Type":  "application/json" },
                body: { user_id: user["id"],
               			remember_token: remember_token }.to_json )
    	rescue => ex
    		response = nil
    	end
		cookies.permanent.signed[:user_id] = user["id"]
		cookies.permanent[:remember_token] = remember_token
	end

	def forget(user)
    	forget_url = getServerUrl() + "/api/users/forget"
    	begin
	        response = HTTParty.post(forget_url, 
				headers: { "Authorization": "Bearer " + session[:token],
						   "Content-Type":  "application/json" },
                body: { user_id: user["id"] }.to_json )
    	rescue => ex
    		response = nil
    	end
	    cookies.delete(:user_id)
	    cookies.delete(:remember_token)
	end

	def current_user
        user_info_url = getServerUrl() + "/api/users/show"
        if !session[:token].nil?
	        begin
	            response = HTTParty.get(user_info_url, 
					headers: { "Authorization": "Bearer " + session[:token] })
	        rescue => ex
	            response = nil
	        end
	        if response.body.nil? || response.body.empty? || response.code != 200
	        	current_user = nil
	        else
	        	current_user = response.parsed_response
	        end
	    elsif (user_id = cookies.signed[:user_id])
	    	remember_url = getServerUrl() + "/api/users/remember"
	    	begin
	    		response = HTTParty.post(remember_url, 
	                headers: { 'Content-Type' => 'application/json' },
	                body: { user_id: user_id,
	                        token: cookies[:remember_token] }.to_json )
	    	rescue => ex
	    		response = nil
	    	end
	        if response.nil? or response.code != 200
	        	current_user = nil
	        else
	        	log_in response.parsed_response["token"]
		        begin
		            response = HTTParty.get(user_info_url, 
						headers: { "Authorization": "Bearer " + session[:token] })
		        rescue => ex
		            response = nil
		        end
		        if response.nil? or response.code != 200
		        	current_user = nil
		        else
		        	current_user = response.parsed_response
		        end
	        end
        else
        	current_user = nil
		end
	end

	def logged_in?
		!current_user.nil?
	end

	def log_out
		session.delete(:token)
		forget(current_user) unless current_user.nil?
		current_user = nil
	end

	# Redirects to stored location (or to the default).
	def redirect_back_or(default)
		redirect_to(session[:forwarding_url] || default)
		session.delete(:forwarding_url)
	end

	# Stores the URL trying to be accessed.
	def store_location
		session[:forwarding_url] = request.original_url if request.get?
	end


	private 

    def logged_in_user
		unless logged_in?
			store_location
			flash[:danger] = oyd_backend_translate("Please log in.", params[:locale])
			redirect_to login_url
		end
    end


end
