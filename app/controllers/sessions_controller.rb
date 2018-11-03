class SessionsController < ApplicationController
	include ApplicationHelper
    include SessionsHelper

	def create
        login_user_url = getServerUrl() + "/oauth/token"
        begin
            response = HTTParty.post(login_user_url, 
                headers: { 'Content-Type' => 'application/json' },
                body: { email: params[:email], 
                    password: params[:password], 
                    grant_type: "password" }.to_json )
        rescue => ex
            response = nil
        end
        if !response.nil? && response.code == 200
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
            if response.nil?
                msg = "Can't access backend"
            else 
                err = response.parsed_response["error"]
                if(err.class.to_s == "String")
                    msg = err
                else 
                    msg = err.join(", ")
                end
            end
            flash[:warning] = oyd_backend_translate(msg, params[:locale])
            redirect_to root_path
        end
	end

	def destroy
        log_out if logged_in?
        log_out if logged_in?
		redirect_to login_url
	end
end
