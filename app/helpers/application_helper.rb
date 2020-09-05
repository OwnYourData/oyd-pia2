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
            when "secret_code"
                "is your OwnYourData Data Vault access code."
            when "sms_error"
                "Error on sending SMS."
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
            when "Email can't be blank, Email is invalid"
                "fehlende Emailadresse"
            when "secret_code"
                "ist der Zugangscode zum OwnYourData Datentresor."
            when "sms_error"
                "Fehler beim SMS Versand."
            else
                msg
            end
        end
    end

    def page_entries_info(collection, options = {})
        %{%s: %d - %d %s %d %s} % [
            t('logs.result'),
            collection.offset + 1,
            collection.offset + collection.length,
            t('logs.of'),
            collection.total_entries,
            t('logs.records')
        ]
      # entry_name = options[:entry_name] || (collection.empty?? 'item' :
      #     collection.first.class.name.split('::').last.titleize)
      # if collection.total_pages < 2
      #   case collection.size
      #   when 0; "No #{entry_name.pluralize} found"
      #   else; "Displaying all #{entry_name.pluralize}"
      #   end
      # else
      #   %{Displaying %d - %d of %d #{entry_name.pluralize}} % [
      #     collection.offset + 1,
      #     collection.offset + collection.length,
      #     collection.total_entries
      #   ]
      # end
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

    def getSemConToken(server_url, app_key, app_secret, scope)
        auth_url = server_url + '/oauth/token'
        query = {
            client_id: ENV["PI2_KEY"],
            client_secret: ENV["PI2_SECRET"],
            scope: "admin",
            grant_type: "client_credentials" }
        response = HTTParty.post(auth_url, query: query)
        token = response.parsed_response["access_token"]
        if token.nil?
            nil
        else
            token
        end
    end

    def addParam(url, param)
        if url.include?("?")
            url + "&" + param.to_s
        else
            url + "?" + param.to_s
        end
    end

    def readRawItems(repo_url, token)
        headers = defaultHeaders(token)
        url_data = addParam(repo_url, 'size=2000')
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
                    url_data = addParam(repo_url, 'page=' + page.to_s + '&size=2000')
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

    def create_item(repo, user_id, params, plugin_id)
        repo_identifier = params[:repo_identifier]
        if repo.nil?
            # check if oyd.settings is available and re-use public_key
            public_key = ''
            @settings_repo = Repo.where(
                user_id: user_id,
                identifier: 'oyd.settings')
            if @settings_repo.count > 0
                public_key = @settings_repo.first.public_key
            end
            repo = Repo.new(
                user_id: user_id,
                identifier: repo_identifier,
                name: repo_identifier,
                public_key: public_key)
            repo.save
        end
        input = params.except( *[:format, 
                                 :controller, 
                                 :action, 
                                 :repo_identifier,
                                 :item] )
        if input[:_json]
            item_array = JSON.parse(input.to_json)['_json']
            if(item_array.class.to_s == 'String')
                item_array = JSON.parse(item_array)
            end
            return_array = []
            return_status = 200
            item_array.each do |item|
                pile_id = item["oyd_source_pile_id"] rescue nil
                if !pile_id.nil?
                    item = item.except( *[ "oyd_source_pile_id" ] )
                end
                retVal = write_item(repo, item.to_json.to_s, pile_id, plugin_id)
                return_array << retVal
                if retVal[:status] != 200
                    status = retVal[:status]
                end
            end
            retVal = { 
                processed: return_array.count, 
                responses: return_array,
                status: 200 }
        else
            pile_id = params[:oyd_source_pile_id] rescue nil
            payload = params.except( *[ :format, 
                                        :controller, 
                                        :action, 
                                        :repo_identifier,
                                        :oyd_source_pile_id,
                                        :item ] ).to_json.to_s
            pile_id = JSON.parse(JSON.parse(payload.to_s.gsub("=>",":"))["value"])["oyd_source_pile_id"] rescue nil
            if !pile_id.nil?
                payload = payload.gsub(',\\"oyd_source_pile_id\\":' + pile_id.to_s, '')
            end
            write_item(repo, payload, pile_id, plugin_id)
        end
    end

    def write_item(repo, payload, pile_id, plugin_id)
        @item = Item.new(value: payload.to_s,
                         repo_id: repo.id,
                         oyd_source_pile_id: pile_id)
        if @item.save
            doc_access(PermType::WRITE, plugin_id, @item.id)
            val = JSON.parse(@item.value)
            val["id"] = @item.id
            @item.update_attributes(value: val.to_json.to_s)
            { id: @item.id, status: 200 }
        else
            {
                error: @item.errors.messages.to_s,
                status: 400 
            }
        end
    end

    def doc_access(operation, plugin_id, item_id=nil, repo_id=nil, query_string=nil)
        @oa = OydAccess.new(
            timestamp: Time.now.utc.to_i,
            operation: operation,
            plugin_id: plugin_id,
            item_id: item_id,
            repo_id: repo_id,
            query_params: query_string,
            user_id: Doorkeeper::Application.find(plugin_id).owner_id)
        if !@oa.save
            puts "error in writing oyd_access"
        end
    end
end
