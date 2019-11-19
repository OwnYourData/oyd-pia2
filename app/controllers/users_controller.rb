class UsersController < ApplicationController
    include ApplicationHelper
    include SessionsHelper
    include UsersHelper

    before_action :logged_in_user, only: [:show, :edit, :update, :updatePwd, :updateRecvPwd, :pia_delete, :data, :plugins, :sources] #, :archive_decrypt, :archive_process]

	require 'httparty'

    def show
        app_index_url = getServerUrl() + "/api/apps/index"
        token = session[:token]
        @installed_apps = HTTParty.get(app_index_url,
            headers: { 'Accept' => '*/*',
                       'Content-Type' => 'application/json',
                       'Authorization' => 'Bearer ' + token }).parsed_response
        @installed_apps_identifier = @installed_apps.map {|x| x["identifier"]}

        current_user_url = getServerUrl() + "/api/users/current"
        @user = HTTParty.get(current_user_url,
             headers: { 'Accept' => '*/*',
                       'Content-Type' => 'application/json',
                       'Authorization' => 'Bearer ' + token }).parsed_response
        @nonce = ""
        begin
            if @user["app_nonce"].to_s != ""
                @nonce = "&NONCE=" + @user["app_nonce"].to_s
            end
        rescue
            @nonce = ""
        end

        # OYD Assistant
        @show_assistant, @assist_text, @assist_type, @assist_id = oyd_assistant(token)

        

        if params[:view].to_s == "2"
            respond_to do |format|
                format.html { render layout: "application_map", template: "users/show2" }
            end
        end
    end

	def new
	end

    def edit
        @user_name = current_user["full_name"]
        @user_email = current_user["email"]
        @user_notif = current_user["email_notif"]
        @user_lang = current_user["language"]
    end

    def update
        token = session[:token]
        if !token.nil?
            update_user_url = getServerUrl + "/api/users/update"
            response = HTTParty.post(update_user_url,
                headers: { 'Content-Type' => 'application/json',
                    'Authorization' => 'Bearer ' + token },
                body: { full_name: params[:full_name],
                        email_notif: params[:notif].nil? ? false : true,
                        language: params[:language] }.to_json )
            if response.nil? or response.code != 200
                current_user = nil
                flash[:warning] = t('account.update_error_message')
            else
                flash[:success] = t('account.update_successful_message')
                current_user = response.parsed_response
            end
        end
        redirect_to account_path(locale: params[:language])
    end

    def updatePwd
        token = session[:token]
        update_pwd_url = getServerUrl() + "/api/users/update_pwd"
        response = HTTParty.post(update_pwd_url,
            headers: { 'Content-Type' => 'application/json',
                       'Authorization' => 'Bearer ' + token },
            body: { old_password: params[:inputPasswordOld],
                    password: params[:inputPasswordNew],
                    password_confirmation: params[:inputPasswordNewVerify] }.to_json )
        if response.code == 200
            flash[:success] = t('account.password_updated')
        else
            err = response.parsed_response["error"]
            if(err.class.to_s == "String")
                msg = err
            else 
                msg = err.join(", ")
            end
            flash[:warning] = oyd_backend_translate(msg, params[:locale])
        end
        redirect_to account_path
    end

    def updateRecvPwd
        token = session[:token]
        update_recv_pwd_url = getServerUrl() + "/api/users/update_recv_pwd"
        response = HTTParty.post(update_recv_pwd_url,
            headers: { 'Content-Type' => 'application/json',
                       'Authorization' => 'Bearer ' + token },
            body: { curr_password: params[:inputPassword],
                    recovery_password: params[:inputRecoverPasswordNew],
                    recovery_password_confirmation: params[:inputRecoverPasswordNewVerify] }.to_json )
        if response.code == 200
            flash[:success] = t('account.recovery_password_updated')
        else
            err = response.parsed_response["error"]
            if(err.class.to_s == "String")
                msg = err
            else 
                msg = err.join(", ")
            end
            flash[:warning] = oyd_backend_translate(msg, params[:locale])
        end
        redirect_to account_path
    end

    def password_reset

    end

    def reset_password
        token = getToken()
        reset_pwd_url = getServerUrl() + "/api/users/reset_password"
        response = HTTParty.post(reset_pwd_url,
            headers: { 'Content-Type' => 'application/json',
                       'Authorization' => 'Bearer ' + token },
            body: { email: params[:email] }.to_json )
        if response.code == 200
            redirect_to info_path(title: t('resetPwd.emailSent'), 
                                  text: t('resetPwd.emailSentInfo'))
        else
            redirect_to info_path(title: t('resetPwd.problemTitle'), 
                                  text: t('resetPwd.problemInfo'))
        end
    end

    def confirm_reset
        @email = params[:email]
        @token = params[:token]
    end

    def perform_password_reset
        token = getToken()
        reset_pwd_url = getServerUrl() + "/api/users/perform_password_reset"
        response = HTTParty.post(reset_pwd_url,
            headers: { 'Content-Type' => 'application/json',
                       'Authorization' => 'Bearer ' + token },
            body: { email:                 params[:email].to_s,
                    token:                 params[:token].to_s,
                    recovery_password:     params[:recovery_password].to_s,
                    password:              params[:password].to_s,
                    password_confirmation: params[:password_confirmation].to_s }.to_json )
        if response.code == 200
            flash[:success] = t('resetPwd.success')
            redirect_to login_path
        else
            flash[:warning] = oyd_backend_translate(response.parsed_response["error"], params[:locale])
            redirect_to confirm_reset_url(token: params[:token].to_s, email: params[:email].to_s)
        end
    end

    def archive_decrypt
        private_key = getReadKey(params[:password].to_s, session[:token].to_s)
        @decrypted_value = decrypt_message(params[:value].to_s, private_key)
        @invalidPwd = false
        if private_key.to_s == ""
            @invalidPwd = true
            respond_to do |format|
                format.js
            end
        else
            cookies.encrypted[:archive] = params[:password].to_s
            redirect_to user_archive_url()
            return
        end
    end

    def user_archive
        token = session[:token]
        password = cookies.encrypted[:archive].to_s
        if token.nil?
            redirect_to login_path
            return
        end
        if password != ""
            archive_url = getServerUrl() + "/api/users/archive"
            response = HTTParty.get(archive_url,
                headers: { 'Content-Type' => 'application/json',
                           'Authorization' => 'Bearer ' + token },
                body: { password: password }.to_json )
            if response.code == 200
                send_data(response.parsed_response.to_json, type: :json, disposition: "attachment")
                return
            else
                flash[:warning] = t('account.archive_error')
                redirect_to account_path
            end
        end
    end

    def pia_delete
        token = session[:token]
        private_key = getReadKey(params[:password].to_s, session[:token].to_s)
        @decrypted_value = decrypt_message(params[:value].to_s, private_key)
        @invalidPwd = false
        if private_key.to_s == ""
            @invalidPwd = true
            respond_to do |format|
                format.js
            end
        else
            pia_delete_url = getServerUrl() + "/api/users/delete"
            response = HTTParty.get(pia_delete_url,
                headers: { 'Content-Type' => 'application/json',
                           'Authorization' => 'Bearer ' + token },
                body: { password: params[:password].to_s }.to_json )
            if response.code == 200
                flash[:success] = t('account.pia_delete_successful')
                redirect_to logout_path
            else
                flash[:warning] = t('account.pia_delete_error')
                redirect_to account_path
            end
        end
    end

    def create
        # if params[:access_code] != "oyd"
        #     flash[:warning] = t('requestDataVault.invalidAccessCode')
        #     redirect_to new_path
        #     return
        # end
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
                     })
        if response.nil? || response.code == 404
            # invalid token => show error
            redirect_to info_path(title: t('account.invalidTokenTitle'), 
                                  text: t('account.invalidTokenText'))
        else
            @full_name = response.parsed_response["full_name"].to_s
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

    def hide_assist
        token = session[:token]
        case params[:assist_type]
        when "new_plugin", "install_app"
            plugin_assist_url = getServerUrl() + "/api/plugin/" + params[:assist_id].to_s + "/assist"
            response = HTTParty.put(plugin_assist_url,
                headers: { 'Content-Type' => 'application/json',
                           'Authorization' => 'Bearer ' + token },
                body: { assist: (params[:hide_assist].to_s == "0") }.to_json )

        when "update_plugin"
            plugin_update_url = getServerUrl() + "/api/plugins/" + params[:assist_id].to_s
            response = HTTParty.put(plugin_update_url,
                headers: { 'Content-Type' => 'application/json',
                           'Authorization' => 'Bearer ' + token },
                body: { assist_update: (params[:hide_assist].to_s == "0") }.to_json )

        when "user_relax"
            user_update_url = getServerUrl() + "/api/users/update"
            response = HTTParty.post(user_update_url,
                headers: { 'Content-Type' => 'application/json',
                           'Authorization' => 'Bearer ' + token },
                body: { assist_relax: (params[:hide_assist].to_s == "0") }.to_json )

        when "configure_source"
            source_update_url = getServerUrl() + "/api/sources/" + params[:assist_id].to_s
            response = HTTParty.put(source_update_url,
                headers: { 'Content-Type' => 'application/json',
                           'Authorization' => 'Bearer ' + token },
                body: { assist_check: (params[:hide_assist].to_s == "0") }.to_json )

        when "inactive_source"
            source_update_url = getServerUrl() + "/api/sources/" + params[:assist_id].to_s
            response = HTTParty.put(source_update_url,
                headers: { 'Content-Type' => 'application/json',
                           'Authorization' => 'Bearer ' + token },
                body: { inactive_check: (params[:hide_assist].to_s == "0") }.to_json )


        else
            puts "Type: " + params[:assist_type]
            puts "ID: " + params[:assist_id]
            puts "Hide Assist: " + params[:hide_assist].to_s

        end
        respond_to do |format|
            format.js
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

    def plugins
        token = session[:token]
        @installed_plugins = HTTParty.get(
            getServerUrl() + "/api/plugins/index", 
                headers: { 'Accept' => '*/*', 
                           'Content-Type' => 'application/json', 
                           'Authorization' => 'Bearer ' + token.to_s }).parsed_response
        @avail = []
        @sam = []
        response = nil
        begin
            response = HTTParty.get("https://sam.data-vault.eu/api/plugins")
        rescue

        end
        if !response.nil? && response.code == 200
            @sam = response.parsed_response
            @sam.each do |item| 
                if item["language"] == I18n.locale.to_s && !@installed_plugins.pluck('identifier').include?(item["identifier"])
                    @avail << [item["id"], item["name"]] 
                end
            end
        end
        @avail << [0, "Manifest:"]
        @plugins = []
        @installed_plugins.each do |plugin|
            plugin["update"] = false
            if plugin["oyd_version"].to_s == ""
                plugin["update"] = true
            else
                @sam.each do |item|
                    if (plugin["identifier"].to_s == item["identifier"].to_s) && ((plugin["language"].to_s == item["language"].to_s) || plugin["language"].to_s == "")
                        if (plugin["oyd_version"].to_s != item["version"].to_s) || (plugin["oyd_version"].to_s == "")
                            plugin["update"] = true
                            break
                        end
                    end
                end
            end
            @plugins << plugin
        end
    end

    def sources
        token = session[:token]
        tmp = HTTParty.get(
            getServerUrl() + "/api/sources/index", 
                headers: { 'Accept' => '*/*', 
                           'Content-Type' => 'application/json', 
                           'Authorization' => 'Bearer ' + token.to_s }).parsed_response
        @sources = []
        tmp.each do |source|
            info = HTTParty.get(
                getServerUrl() + "/api/sources/" + source["id"].to_s,  
                headers: { 'Accept' => '*/*', 
                           'Content-Type' => 'application/json', 
                           'Authorization' => 'Bearer ' + token.to_s })
            if info.code == 200
                if source["configured"]
                    source["last_record"] = Date.parse(info.parsed_response["last"].to_s) rescue ""
                    source["record_count"] = info.parsed_response["count"]
                else
                    source["last_record"] = t('sources.not_configured')
                    source["record_count"] = ""
                end
            else
                source["last_record"] = "Error"
                source["record_count"] = ""
            end
            @sources << source
        end
    end

    def show_location
        pia_url = getServerUrl()
        token = session[:token]
        master_key = params[:mk].to_s
        headers = defaultHeaders(token)
        current_user_url = pia_url + "/api/users/current"
        @user = HTTParty.get(current_user_url,
             headers: headers).parsed_response
        nonce = @user["app_nonce"].to_s

        nonce_url = pia_url + "/api/support/" + nonce
        response = HTTParty.get(nonce_url)
        cipher = response.parsed_response["cipher"]
        cipherHex = [cipher].pack('H*')
        nonceHex = [nonce].pack('H*')
        keyHash = [master_key].pack('H*')
        private_key = RbNaCl::PrivateKey.new(keyHash)
        authHash = RbNaCl::Hash.sha256('auth'.force_encoding('ASCII-8BIT'))
        auth_key = RbNaCl::PrivateKey.new(authHash).public_key
        box = RbNaCl::Box.new(auth_key, private_key)
        password = box.decrypt(nonceHex, cipherHex)
        decrypt_key = decrypt_message(@user["password_key"], password)

        location_items_url = pia_url + "/api/repos/oyd.location/items?last_days=14"
        @location_items = readRawItems(location_items_url, token)
        @items = []
        @location_items.each do |item|
            retVal = decrypt_message(item.to_s, decrypt_key)
            if retVal.to_s != ""
                retVal = JSON.parse(retVal)
                retVal["id"] = JSON.parse(item)["id"]
                @items << retVal
            end
        end

        respond_to do |format|
            format.js
        end
    end
end
