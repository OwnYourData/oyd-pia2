class UsersController < ApplicationController
    include ApplicationHelper
    include SessionsHelper

    before_action :logged_in_user, only: [:show, :edit, :data]

	require 'httparty'

    def show
        app_index_url = getServerUrl() + "/api/apps/index"
        token = session[:token]
        @installed_apps = HTTParty.get(app_index_url,
            headers: { 'Accept' => '*/*',
                       'Content-Type' => 'application/json',
                       'Authorization' => 'Bearer ' + token }).parsed_response
        @installed_apps_identifier = @installed_apps.map {|x| x["identifier"]}
        # if ENV["SAM"] != 'disable'
        #     @apps = HTTParty.get("https://sam2.datentresor.org/api/plugins").parsed_response
        # end
    end

	def new
	end

    def edit
        @user_email = @current_user["email"]
        @user_name = @current_user["full_name"]
    end

    def update
        # !!! fix me
        redirect_to account_path
    end

    def create
        if params[:access_code] != "oyd"
            flash[:warning] = t('requestDataVault.invalidAccessCode')
            redirect_to new_path
            return
        end
        token = getToken()
        if !token.nil?
            create_user_url = getServerUrl() + "/api/users/create"
            response = HTTParty.post(create_user_url,
                headers: { 'Content-Type' => 'application/json',
                    'Authorization' => 'Bearer ' + token },
                body: { name: params[:name],
                    email: params[:email],
                    language: params[:locale],
                    frontend_url: ENV['VAULT_URL'].to_s }.to_json )
        else
            response = nil
        end
        if !response.nil? && response.code == 200
            # flash[:info] = t('process.confirmationMailSent')
            redirect_to info_path(title: t('process.confirmationMailSent'), 
                text: t('process.confirmationMailSentBody'))
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
            redirect_to new_path
        end
    end


    def new_account
        token = getToken()
        if !token.nil?
            create_user_url = getServerUrl() + "/api/users/create"
            response = HTTParty.post(create_user_url,
                headers: { 'Content-Type' => 'application/json',
                    'Authorization' => 'Bearer ' + token },
                body: { 
                    name: params[:name],
                    email: params[:email],
                    language: params[:locale],
                    frontend_url: ENV['VAULT_URL'].to_s }.to_json )
        else
            response = nil
        end
        if !response.nil? && response.code == 200
            render json: {}, status: 200
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
            render json: {message: oyd_backend_translate(msg, params[:locale])},
                   status: 500
            redirect_to new_path
        end
    end


	def confirm
        @full_name = ""
        token = getToken()
        full_name_by_token_url = getServerUrl() + 
            "/api/users/name_by_token/" + params[:token]
        response = HTTParty.get(full_name_by_token_url,
            headers: { 'Accept' => '*/*',
                       'Content-Type' => 'application/json',
                       'Authorization' => 'Bearer ' + token 
                     }).parsed_response
        if !response.nil? & !response["full_name"].nil?
            @full_name = response["full_name"].to_s
        end
	end

	def confirm_email
        token = getToken()

        name_by_token_url = getServerUrl() + 
            "/api/users/name_by_token/" + params[:token]
        email_response = HTTParty.get(name_by_token_url,
            headers: { 'Accept' => '*/*',
                       'Content-Type' => 'application/json',
                       'Authorization' => 'Bearer ' + token 
                     }).parsed_response

        confirm_user_url = getServerUrl() + "/api/users/confirm"
        response = HTTParty.post(confirm_user_url,
            headers: { 'Content-Type' => 'application/json',
                'Authorization' => 'Bearer ' + token },
            body: { 
                full_name: params[:full_name],
                password: params[:password],
                password_confirmation: params[:password_confirmation],
                recovery_password: params[:recovery_password],
                recovery_password_confirmation: params[:recovery_password_confirmation],
                token: params[:token] }.to_json )
        if response.code == 200
            flash[:info] = t('process.accountConfirmed')

            if !email_response.nil? & !email_response["email"].nil?
                email = email_response["email"].to_s
                login_user_url = getServerUrl() + "/oauth/token"
                begin
                    response = HTTParty.post(login_user_url, 
                        headers: { 'Content-Type' => 'application/json' },
                        body: { email: email, 
                                password: params[:password], 
                                grant_type: "password" }.to_json )
                rescue => ex
                    response = nil
                end
                if !response.nil? && response.code == 200
                    token = response.parsed_response["access_token"].to_s
                    log_in token
                    redirect_to user_path
                    return
                end
            end
            redirect_to login_path
        else
            err = response.parsed_response["error"]
            if(err.class.to_s == "String")
                msg = err
            else 
                msg = err.join(", ")
            end
            flash[:warning] = oyd_backend_translate(msg, params[:locale])
            redirect_to users_confirm_email_path(request.parameters)
        end
    end

    def data
        token = session[:token]
        record_count_url = getServerUrl() + "/api/users/record_count"
        response = HTTParty.get(record_count_url,
            headers: { 'Accept' => '*/*',
                       'Content-Type' => 'application/json',
                       'Authorization' => 'Bearer ' + token }).parsed_response
        @record_count = response["count"]
        @apps_count = 0
        @repos = HTTParty.get(
            getServerUrl() + "/api/repos/index", 
                headers: { 'Accept' => '*/*', 
                           'Content-Type' => 'application/json', 
                           'Authorization' => 'Bearer ' + token.to_s }).parsed_response
    end

    def permissions
        token = session[:token]
        @plugins = HTTParty.get(
            getServerUrl() + "/api/plugins/index", 
                headers: { 'Accept' => '*/*', 
                           'Content-Type' => 'application/json', 
                           'Authorization' => 'Bearer ' + token.to_s }).parsed_response
    end
end
