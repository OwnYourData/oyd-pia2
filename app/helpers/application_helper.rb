module ApplicationHelper
	require 'base64'

	def base64?(value)
		value.is_a?(String) && Base64.encode64(Base64.decode64(value)).delete("\n") == value
	end

    # Returns the full title on a per-page basis.
    def full_title(page_title = '')
        base_title = "OwnYourData"
        if page_title.empty?
            base_title
        else
            page_title + " | " + base_title
        end
    end

  	def oyd_backend_translate(msg, lang)
        if lang == "en"
            case msg
            when "invalid_grant"
                "invalid credentials"
            else
                msg
            end
        else
            case msg
            when "Please log in."
            	"Bitte melde dich an."
            when "Can't access backend"
                "auf Datenbank kann nicht zugegriffen werden"
            when "Not authorized"
                "unerlaubter Zugriff"
            when "Email can't be blank"
                "Email darf nicht leer sein"
            when "Email is invalid"
                "ungültige Emailadresse"
            when "Email has already been taken"
                "diese Emailadresse ist bereits in Verwendung"

            when "Password can't be blank"
                "Das Passwort darf nicht leer sein."
            when "Recovery password can't be blank"
                "Das Wiederherstellungspasswort darf nicht leer sein."
            when "Password confirmation can't be blank"
                "Die Passwortbestätigung darf nicht leer sein."
            when "Recovery password confirmation can't be blank"
                "Die Bestätigung für das Wiederherstellungspasswort darf nicht leer sein."
            when "Recovery password shall not match password"
                "Passwort und Passwort zur Wiederherstellung dürfen nicht übereinstimmen."
            when "Password confirmation does not match password"
                "Passwort und Passwortbestätigung stimmen nicht überein."
            when "Recovery password confirmation does not match recovery password"
                "Wiederherstellungspasswort und Bestätigung des Wiederherstellungspassworts stimmen nicht überein."

            when "password mismatch"
                "die Passwörter sind ungültig oder stimmen nicht überein"
            when "invalid token"
                "ungültiger Token"
            when "Password is too short (minimum is 6 characters)"
                "Das Passwort ist zu kurz (Minimum sind 6 Zeichen)"

            when "invalid_grant"
                "ungültige Zugangsdaten"
            else
                msg
            end
        end
    end

    def getServerUrl
        retVal = ENV["LOCAL_VAULT"]
        retVal ||= 'http://localhost:3000'
        retVal
        #'http://localhost:3000' #ENV["PIA_URL"]
    end

    def getToken
        auth_url = getServerUrl() + "/oauth/token"
        app_key = Doorkeeper::Application.first.uid #ENV["APP_KEY"]
        app_secret = Doorkeeper::Application.first.secret #ENV["APP_SECRET"]
        begin
            response = HTTParty.post(auth_url, 
                headers: { 'Content-Type' => 'application/json' },
                body: { client_id: app_key, 
                    client_secret: app_secret, 
                    grant_type: "client_credentials" }.to_json )
        rescue => ex
            response = nil
        end
        if response.nil?
            nil
        else
            response.parsed_response["access_token"].to_s
        end
    end

end
