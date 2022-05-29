class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception, unless: -> { request.format.json? }
    before_action :set_locale, :cors_preflight_check
    after_action :cors_set_access_control_headers
    rescue_from ActionController::InvalidAuthenticityToken, with: :redirect_to_login_path

    def redirect_to_login_path
        redirect_to login_path
    end
    
    include SessionsHelper

    def missing
        flash[:warning] = "The following page does not exist: " + request.original_url
        redirect_to root_url
    end

    def default_url_options(options={})
        I18n.locale == :en ? {} : { locale: I18n.locale }
    end

    def cors_preflight_check
        if request.method == 'OPTIONS'
            headers['Access-Control-Allow-Origin'] = '*'
            headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
            headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version, Token'
            headers['Access-Control-Max-Age'] = '1728000'
            headers['Access-Control-Expose-Headers'] = '*'

            render text: '', content_type: 'text/plain'
        end
    end

    def cors_set_access_control_headers
        headers['Access-Control-Allow-Origin'] = '*'
        headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
        headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, Token'
        headers['Access-Control-Max-Age'] = "1728000"
        headers['Access-Control-Expose-Headers'] = '*'
    end

    def doorkeeper_unauthorized_render_options(error: nil)
        { json: { error: "Not authorized" } }
    end

    def oidc
        endpoint_url = ""
        begin
            code = params[:code].to_s
            state = params[:state].to_s
            puts "Code: " + code
            puts "State: " + state

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

            pr_url = endpoint_core_url + "/api/data/proofrequest/prooftemplate"
            pr_url += "?tenant=" + tenant_id
            pr_url += "&identityID=" + user_identity
            pr_url += "&creator=" + verifier_identity
            pr_url += "&name=Login_" + Time.now.to_i.to_s
            pr_url += "&proofTemplateID=" + proof_id
            pr_response = HTTParty.post(pr_url,
                headers: { 'Content-Type' => 'application/json', 
                           'Authorization' => "Bearer " + token_response.parsed_response["id_token"]})
            proof_response_id = pr_response.parsed_response["id"].to_s
            redirect_to oidc_path(prid: proof_response_id)

        rescue Exception => e
            if endpoint_url.to_s == ""
                endpoint_url = "https://auth-ssi-demo.esatus.com" rescue ""
            end
            logout_url = endpoint_url + "/services/idp/logout" rescue ""
            redirect_to logout_url
            # logout_response = HTTParty.get(logout_url) rescue nil
            # render json: {"error": "#{e}"},
            #        status: 500
        end
    end


    private

    def extract_locale_from_accept_language_header
        hal = request.env['HTTP_ACCEPT_LANGUAGE']
        if hal
            retval = hal.scan(/^[a-z]{2}/).first
            if "-en-de-".split(retval).count == 2
                retval
            else
                I18n.default_locale
            end
        else
            I18n.default_locale
        end
    end

    def set_locale
        I18n.locale = params[:locale] || extract_locale_from_accept_language_header
        Rails.application.routes.default_url_options[:locale]= I18n.locale
    end

    def current_resource_owner
        if doorkeeper_token
            if doorkeeper_token.resource_owner_id.nil?
                nil
            else
                if User.where(id: doorkeeper_token.resource_owner_id).count > 0
                    User.find(doorkeeper_token.resource_owner_id)
                else
                    nil
                end
            end
        else
            nil
        end
    end

end
