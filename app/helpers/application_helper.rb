module ApplicationHelper
	require 'base64'

	def base64?(value)
		value.is_a?(String) && Base64.encode64(Base64.decode64(value)).delete("\n") == value
	end

    def float?(string)
      true if Float(string) rescue false
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
                "Invalid credentials"
            when "invalid password"
                "Invalid current password."
            when "invalid recovery password"
                "Invalid recovery password."
            when "unauthorized"
                "Invalid credentials"
            when "invalid input"
                "Invalid input - the record was not saved"
            when "unmet dependency"
                "The plugin cannot be installed because of unmet dependencies. Make sure to install other plugins first!"
            when "invalid request"
                "Invalid request - please restart password recovery"
            when "invalid request token"
                "Invalid Token - please restart password recovery"
            when "expired token"
                "Expired Token - please restart password recovery"
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
            when "Password confirmation doesn't match Password"
                "Passwort und Passwortbestätigung stimmen nicht überein."
            when "Recovery password confirmation does not match recovery password"
                "Wiederherstellungspasswort und Bestätigung des Wiederherstellungspassworts stimmen nicht überein."
            when "password mismatch"
                "die Passwörter sind ungültig oder stimmen nicht überein"
            when "invalid token"
                "ungültiger Token"
            when "Password is too short (minimum is 6 characters)"
                "Das Passwort ist zu kurz (Minimum sind 6 Zeichen)"
            when "invalid password"
                "Aktuelles Passwort ist ungültig."
            when "invalid recovery password"
                "Ungültiges Wiederherstellungspasswort."
            when "invalid_grant"
                "ungültige Zugangsdaten"
            when "unauthorized"
                "ungültige Zugangsdaten"
            when "invalid input"
                "Ungültige Eingabe - die Daten wurden nicht gespeichert"
            when "unmet dependency"
                "Die Erweiterung kann aufgrund von fehlenden Abhängigkeiten nicht installiert werden. Versuche andere Erweiterungen vorher zu installieren!"
            when "invalid request"
                "Ungültige Anfrage - bitte starte den Prozess zum Zurücksetzen des Passworts erneut"
            when "invalid request token"
                "Ungültiger Token - bitte starte den Prozess zum Zurücksetzen des Passworts erneut"
            when "expired token"
                "Abgelaufener Token - bitte starte den Prozess zum Zurücksetzen des Passworts erneut"
            when "Password too short"
                "Passwort zu kurz"
            when "Invalid recovery password"
                "Ungültiges Wiederherstellungs-Passwort"
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

    def defaultHeaders(token)
      { 'Accept' => '*/*',
        'Content-Type' => 'application/json',
        'Authorization' => 'Bearer ' + token.to_s }
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

    def readRawItems(app, repo_url)
        headers = defaultHeaders(app["token"])
        url_data = repo_url + '?size=2000'
        response = HTTParty.get(url_data,
            headers: headers)
        response_parsed = response.parsed_response
        if response_parsed.nil? or 
                response_parsed == "" or
                response_parsed.include?("error")
            nil
        else
            recs = response.headers["total-count"].to_i
            if recs > 2000
                (2..(recs/2000.0).ceil).each_with_index do |page|
                    url_data = repo_url + '?page=' + page.to_s + '&size=2000'
                    subresp = HTTParty.get(url_data,
                        headers: headers).parsed_response
                    response_parsed = response_parsed + subresp
                end
                response_parsed
            else
                response_parsed
            end
        end
    end

    def key_encrypt(message, key)
        keyHash = RbNaCl::Hash.sha256(key.force_encoding('ASCII-8BIT'))
        private_key = RbNaCl::PrivateKey.new(keyHash)
        public_key = private_key.public_key
        authHash = RbNaCl::Hash.sha256('auth'.force_encoding('ASCII-8BIT'))
        auth_key = RbNaCl::PrivateKey.new(authHash)
        box = RbNaCl::Box.new(public_key, auth_key)
        nonce = RbNaCl::Random.random_bytes(box.nonce_bytes)
        msg = message.force_encoding('ASCII-8BIT')
        cipher = box.encrypt(nonce, msg)
        { 
            value: cipher.unpack('H*')[0], 
            nonce: nonce.unpack('H*')[0]
        }.to_json
    end

    def getReadKey(password, token)
        headers = defaultHeaders(token)
        user_url = getServerUrl() + '/api/users/current'
        response = HTTParty.get(user_url, headers: headers).parsed_response
        if response.key?("password_key")
            decrypt_message(response["password_key"], password)
        else
            nil
        end
    end

    def decrypt_message(message, keyStr)
        begin
            cipher = [JSON.parse(message)["value"]].pack('H*')
            nonce = [JSON.parse(message)["nonce"]].pack('H*')
            keyHash = RbNaCl::Hash.sha256(keyStr.force_encoding('ASCII-8BIT'))
            private_key = RbNaCl::PrivateKey.new(keyHash)
            authHash = RbNaCl::Hash.sha256('auth'.force_encoding('ASCII-8BIT'))
            auth_key = RbNaCl::PrivateKey.new(authHash).public_key
            box = RbNaCl::Box.new(auth_key, private_key)
            box.decrypt(nonce, cipher)
        rescue
            nil
        end
    end

    def check_permission(repo_identifier, app, perm_type)
        if app.is_a?(ActiveRecord::Base)
            if Permission.where(
                    plugin_id: app.id, 
                    perm_type: perm_type,
                    perm_allow: true).count > 0
                if repo_identifier.match?(/#{Permission.where(
                            plugin_id: app.id, 
                            perm_type: perm_type,
                            perm_allow: true
                        ).pluck(:repo_identifier).join('|')}/)
                    true
                else
                    false
                end
            else
                false
            end
        else
            if app.count == 0
                return false
            end
            if Permission.where(
                    plugin_id: app.pluck(:id), 
                    perm_type: perm_type,
                    perm_allow: true).count > 0
                if !repo_identifier.nil?
                    if repo_identifier.match?(/#{Permission.where(
                                plugin_id: app.pluck(:id), 
                                perm_type: perm_type,
                                perm_allow: true
                            ).pluck(:repo_identifier).join('|')}/)
                        true
                    else
                        false
                    end
                else
                    false
                end
            else
                false
            end
        end
    end
end
