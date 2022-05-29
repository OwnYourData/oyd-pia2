class SessionsController < ApplicationController
	include ApplicationHelper
    include SessionsHelper

	def create
        if params.has_key?(:phone_code)
            # validate phone_code
            @phone_number = params[:password].to_s
            @user = User.find_by_email(Base64.strict_encode64(Digest::SHA256.digest(@phone_number)).downcase)
            if @user.nil?
                flash[:warning] = oyd_backend_translate("invalid_grant", params[:locale])
                redirect_to phone_login_path
                return
            end
            if params[:phone_code].to_s != @user.sms_code.to_s
                flash[:warning] = oyd_backend_translate("invalid_grant", params[:locale])
                redirect_to phone_login_path
                return
            end                
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

    def login_sowl
        @app = Doorkeeper::Application.find_by_name("oidc")
        if @app.nil?
            render json: {"error": "invalid application_id"},
                   status: 500
            return
        end
        endpoint_url = @app.oidc_token_endpoint.to_s
        tenant_id = @app.oidc_tenant_id.to_s
        app_id = @app.oidc_app_id.to_s
        redirect_uri = @app.oidc_redirect_uri.to_s
        code_challenge = SecureRandom.urlsafe_base64(43)
        nonce = (JWT.encode SecureRandom.uuid + SecureRandom.uuid, nil, 'HS256')[0..-45]
        # nonce = "637728164799768922.ZTFlMGExMDAtNzM5Yi00YzZmLWE2ZjgtZWNjYWYyYTQ0M2ZjMTUxZDIwMTMtNWRlMC00ZDRhLTlmMjgtYmZlZGU2YTlhNzdm"
        state = SecureRandom.urlsafe_base64(390)
        # state = "CfDJ8AJHmtZOB61NtoLRMnMfYlCELyim7bchdyBjD6awex2d2MlY0hQUz_4ncJwWNfsT9D9DBQFnpoRoTTPV4UnhRmF98sc51KpElqB1EnSj4fGAtqHA9EEVR_E3MB-2OeodGL_fZSiAiLKREavE5zEXgV0RzoijLCkkUk62Ldl8trFKAKzhaYNpIHb7YJfDtVzfkco3j8waWjcW2OVN8f2FYtLOL6qNHaCiEo21H-aDBRaUIY73yJmn0vAYOCcLmBxsO9m49mnpTmFiSb0bCUbN_g-DMXzAlyEBixmVfYZyVWqt2uSsdIW9Y28qA-4u8oVbdSLeQ6eYgSPsTWYNMQAmqFQihZY_KHG_HWkJ89jPeaqXTQa25wPHrG-eW0h7SkznrA"

        sowl_url = endpoint_url + "/services/idp/oidc/authorize?"
        sowl_url += "tenant=" + tenant_id + "&"
        sowl_url += "client_id=" + app_id + "&"
        sowl_url += "redirect_uri=" + redirect_uri + "&"
        sowl_url += "response_type=code&"
        sowl_url += "scope=openid%20raw&"
        sowl_url += "code_challenge=" + code_challenge + "&"
        sowl_url += "code_challenge_method=S256&"
        sowl_url += "response_mode=form_post&"
        sowl_url += "nonce=" + nonce + "&"
        sowl_url += "state=" + state
        redirect_to sowl_url
    end

    def oidc
        code = params[:code].to_s
        state = params[:state].to_s
        prid = params[:prid].to_s
        puts "Code: " + code
        puts "State: " + state
        puts "Proof Response ID: " + prid

        @app = Doorkeeper::Application.find_by_name("oidc")
        if @app.nil?
            render json: {"error": "invalid application_id"},
                   status: 500
            return
        end
        endpoint_url = @app.oidc_token_endpoint.to_s
        endpoint_core_url = @app.oidc_core_endpoint.to_s
        oidc_identifier = @app.oidc_identifier.to_s
        oidc_secret = @app.oidc_secret.to_s
        oidc_api_secret = @app.oidc_api_secret.to_s
        redirect_uri = @app.oidc_redirect_uri.to_s
        tenant_id = @app.oidc_tenant_id.to_s
        verifier_id = @app.oidc_verifier_id.to_s
        proof_id = @app.oidc_login_proof_template_id.to_s

        token_url = endpoint_url + "/services/idp/oidc/token?"
        token_url += "grant_type=id_token&"
        token_url += "code=" + code + "&"
        token_url += "redirect_uri=" + redirect_uri + "&"
        token_url += "client_id=" + oidc_identifier + "&"
        token_url += "client_secret=" + oidc_secret

        timeout = false
        begin
            response = HTTParty.post(token_url, timeout: 15)
        rescue
            timeout = true
        end
        if timeout or response.nil? or response.code != 200
            response_code = response.code rescue 500
            render json: {"error": "OIDC token request failed"}, 
                   status: response_code
            return
        end

        id_token = response.parsed_response["id_token"]
        access_token = response.parsed_response["access_token"] rescue ""
        expires_in = response.parsed_response["expires_in"].to_i rescue 60
        decoded_token = JWT.decode id_token, nil, false
        user_id = decoded_token.first["sub"]
        entitlements = decoded_token.first["entitlements"]

        # retrieve Token (only valid 60s)
        auth_token = Base64.strict_encode64(oidc_identifier + ":" + oidc_api_secret)
        token_response = HTTParty.post(endpoint_core_url + "/api/authentication/authenticateAPIConsumerOIDC", 
            headers: { 'Content-Type' => 'application/json', 'Authorization' => 'Basic ' + auth_token})

        # retrieve user identity
        user_response = HTTParty.get(endpoint_core_url + "/api/data/identity/name/" + user_id + "?tenant=" + tenant_id, 
            headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer " + token_response.parsed_response["id_token"]})
        user_identity = user_response.parsed_response["id"].to_s

        # retrieve verifier identity
        verifier_response = HTTParty.get(endpoint_core_url + "/api/data/identity/name/" + verifier_id + "?tenant=" + tenant_id, 
            headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer " + token_response.parsed_response["id_token"]})
        verifier_identity = verifier_response.parsed_response["id"].to_s

        if prid.to_s == ""
            # create proof request
            pr_url = endpoint_core_url + "/api/data/proofrequest/prooftemplate"
            # pr_url = endpoint_core_url + "/api/proofrequest"
            pr_url += "?tenant=" + tenant_id
            pr_url += "&identityID=" + user_identity
            pr_url += "&creator=" + verifier_identity
            pr_url += "&name=Login_" + Time.now.to_i.to_s
            pr_url += "&proofTemplateID=" + proof_id
            pr_response = HTTParty.post(pr_url,
                headers: { 'Content-Type' => 'application/json', 
                           'Authorization' => "Bearer " + token_response.parsed_response["id_token"]})
            proof_response_id = pr_response.parsed_response["id"].to_s
        else
            proof_response_id = prid
        end

        # retrieve Token (only valid 60s)
        auth_token = Base64.strict_encode64(oidc_identifier + ":" + oidc_api_secret)
        token_response = HTTParty.post(endpoint_core_url + "/api/authentication/authenticateAPIConsumerOIDC", 
            headers: { 'Content-Type' => 'application/json', 'Authorization' => 'Basic ' + auth_token})

        # invoke rule engine
        rule_url = endpoint_core_url + "/api/data/rule/service?"
        rule_url += "tenant=" + tenant_id
        rule_response = HTTParty.get(rule_url,
            headers: { 'Content-Type' => 'application/json', 
                       'Authorization' => "Bearer " + token_response.parsed_response["id_token"]})

        # read content of proof
        pc_url = endpoint_core_url + "/api/data/proofrequest/" + proof_response_id.to_s + "?"
        pc_url += "tenant=" + tenant_id
        pc_response = HTTParty.get(pc_url,
            headers: { 'Content-Type' => 'application/json', 
                       'Authorization' => "Bearer " + token_response.parsed_response["id_token"]})

        @message = "your login was confirmed - please wait to be logged in..."
        @complete = true
        begin
            @email = JSON.parse(pc_response.parsed_response["proofJson"])["requested_proof"]["revealed_attr_groups"].first.last["values"]["email"]["raw"]
            enc_pwd = JSON.parse(pc_response.parsed_response["proofJson"])["requested_proof"]["revealed_attr_groups"].first.last["values"]["password"]["raw"]

            key = ENV["OIDC_SYMKEY"].to_s
            secret_box = RbNaCl::SecretBox.new(Base64.decode64(key))
            nonce64 = "kpkdI3z6Wtrv7k5daM7Z95ZKl0bb8OHG"
            @password = secret_box.decrypt(Base64.decode64(nonce64), Base64.decode64(enc_pwd))
        rescue
            if prid.to_s == ""
                redirect_to oidc_path(code: code, state: state, prid: proof_response_id)
                return
            end
            @message = "please confirm login"
            @complete = false
        end
        if @complete
            pd_url = endpoint_core_url + "/api/data/proofrequest/" + proof_response_id + "?"
            pd_url += "tenant=" + tenant_id
            pd_response = HTTParty.delete(pd_url,
                headers: { 'Content-Type' => 'application/json', 
                           'Authorization' => "Bearer " + token_response.parsed_response["id_token"]})
        end
        render layout: "application_reload"
    end

	def destroy
        begin
            log_out if logged_in?
            log_out if logged_in?
            # redirect_to "https://auth-ssi-demo.esatus.com/services/idp/logout"
    		redirect_to login_url
        rescue
            redirect_to login_url
        end
	end
end
