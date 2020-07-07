class SessionsController < ApplicationController
	include ApplicationHelper
    include SessionsHelper

	def create
        if params.has_key?(:phone_code)
            # validate phone_code
        end
        login_user_url = getServerUrl() + "/oauth/token"
        response_nil = false
        begin
            response = HTTParty.post(login_user_url, 
                headers: { 'Content-Type' => 'application/json' },
                body: { email: params[:email], 
                    password: params[:password], 
                    grant_type: "password" }.to_json )
        rescue => ex
            response_nil = true
        end
        if !response_nil && !response.body.nil? && response.code == 200
            token = response.parsed_response["access_token"].to_s
            log_in token
            params[:remember] == '1' ? remember(current_user) : forget(current_user)

            app_support_url = getServerUrl() + "/api/users/app_support"
            response = HTTParty.post(app_support_url,
                headers: { 'Content-Type' => 'application/json',
                           'Authorization' => 'Bearer ' + token },
                body: { nonce: params[:nonce],
                        cipher: params[:cipher] }.to_json )
            redirect_back_or user_path
        else
            if response.to_s == ""
                msg = "Can't access backend"
            else 
                err = response.parsed_response["error"]
                if(err.class.to_s == "String")
                    msg = err
                else 
                    msg = err.join(", ") rescue ""
                end
            end
            flash[:warning] = oyd_backend_translate(msg, params[:locale])
            if params.has_key?(:phone_code)
                redirect_to phone_login_path
            else
                redirect_to root_path
            end
        end
	end

	def destroy
        log_out if logged_in?
        log_out if logged_in?
		redirect_to login_url
	end
end
