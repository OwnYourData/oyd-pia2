module UsersHelper
    def oyd_assistant(token)
        found = false
        assist_text = ""
        assist_type = ""
        assist_id = ""

        # check if OYD app is installed (= location records exist)
        if !found
            oyd_app = false
            items_url = getServerUrl() + '/api/repos/oyd.location/identifier'
            response = HTTParty.get(items_url, 
                    headers: { 'Accept' => '*/*', 
                               'Content-Type' => 'application/json', 
                               'Authorization' => 'Bearer ' + token.to_s }).parsed_response
            if response == 200
                begin
                    if response["items"].to_i > 0
                        oyd_app = true
                    end
                rescue
                    oyd_app = false
                end
            end

            if !oyd_app
                tmp = HTTParty.get(getServerUrl() + "/api/plugin/oyd.location/assist", 
                        headers: { 'Accept' => '*/*', 
                                   'Content-Type' => 'application/json', 
                                   'Authorization' => 'Bearer ' + token.to_s }).parsed_response
                if tmp["assist"]
                    found = true
                    if I18n.locale.to_s == "de"
                        assist_text = "<p>Hast du schon die OwnYourData App auf deinem Handy installiert? Damit kannst du auf deinen Datentresor vom Handy aus zugreifen und gleichzeitig deine GPS Daten aufzeichnen! Führe die folgenden Schritte durch, um die App zu installieren:</p>"
                        assist_text += "<ol><li>wähle im Benutzermenü <span class='glyphicon glyphicon-user'></span> rechts oben den Eintrag 'Einstellungen'</li>"
                        assist_text += "<li>verwende die Links zum Apple AppStore oder dem Google PlayStore im grauen Feld</li>"
                        assist_text += "<li>folge den Anweisungen zur Installation und Einrichtung der App</li></ol>"
                    else
                        assist_text = "<p>Have you already installed the OwnYourData app on your mobile? It lets you access your data vault from your phone and allows you to recordyour GPS data! Follow these steps to install the app:</p>"
                        assist_text += "<ol><li>open the user menu <span class='glyphicon glyphicon-user'></span> in the upper right corner and select 'Settings'</li>"
                        assist_text += "<li>use the links to the Apple AppStore or Google PlayStore in the gray box</li>"
                        assist_text += "<li>follow the instructions to install and set up the app</li></ol>"
                    end
                    assist_type = "install_app"
                    assist_id = "oyd.location"
                end
            end
        end

        # check to update plugins
        if !found
            @installed_plugins = HTTParty.get(
                getServerUrl() + "/api/plugins/index", 
                    headers: { 'Accept' => '*/*', 
                               'Content-Type' => 'application/json', 
                               'Authorization' => 'Bearer ' + token.to_s }).parsed_response
            @avail = []
            @sam = []
            response = HTTParty.get("https://sam.oydapp.eu/api/plugins")
            if response.code == 200
                @sam = response.parsed_response
            end
            @plugins = []
            @installed_plugins.each do |plugin|
                if plugin["oyd_version"].to_s == ""
                    if plugin["assist_update"].nil? | plugin["assist_update"]
                        found = true
                        if I18n.locale.to_s == "de"
                            assist_text = "<p>Für die Erweiterung '" + plugin["name"].to_s + "' gibt es eine neue Version! Führe die folgenden Schritte durch, um die Erweiterung zu aktualisieren:</p>"
                            assist_text += "<ol><li>wähle im Benutzermenü <span class='glyphicon glyphicon-user'></span> rechts oben den Eintrag 'Erweiterungen'</li>"
                            assist_text += "<li>klicke bei der Erweiterung '" + plugin["name"].to_s + "' auf 'Aktualisieren' und folge den Anweisungen</li></ol>"
                        else
                            assist_text = "<p>A new version is available for the plugin '" + plugin["name"].to_s + "'! Follow these steps to update the plugin:</p>"
                            assist_text += "<ol><li>open the user menu <span class='glyphicon glyphicon-user'></span> in the upper right corner and select 'Plugins'</li>"
                            assist_text += "<li>click 'Update' for the plugin '" + plugin["name"].to_s + "' and follow the instructions</li></ol>"
                        end
                        assist_type = "update_plugin"
                        assist_id = plugin["id"]
                        break
                    end
                else
                    @sam.each do |item|
                        if (plugin["identifier"].to_s == item["identifier"].to_s) && ((plugin["language"].to_s == item["language"].to_s) || plugin["language"].to_s == "")
                            if (plugin["oyd_version"].to_s != item["version"].to_s)
                                if plugin["assist_update"].nil? | plugin["assist_update"]
                                    found = true
                                    if I18n.locale.to_s == "de"
                                        assist_text = "<p>Für die Erweiterung '" + plugin["name"].to_s + "' gibt es eine neue Version! Führe die folgenden Schritte durch, um die Erweiterung zu aktualisieren:</p>"
                                        assist_text += "<ol><li>wähle im Benutzermenü <span class='glyphicon glyphicon-user'></span> rechts oben den Eintrag 'Erweiterungen'</li>"
                                        assist_text += "<li>klicke bei der Erweiterung '" + plugin["name"].to_s + "' auf 'Aktualisieren' und folge den Anweisungen</li></ol>"
                                    else
                                        assist_text = "<p>A new version is available for the plugin '" + plugin["name"].to_s + "'! Follow these steps to update the plugin:</p>"
                                        assist_text += "<ol><li>open the user menu <span class='glyphicon glyphicon-user'></span> in the upper right corner and select 'Plugins'</li>"
                                        assist_text += "<li>click 'Update' for the plugin '" + plugin["name"].to_s + "' and follow the instructions</li></ol>"
                                    end
                                    assist_type = "update_plugin"
                                    assist_id = plugin["id"]
                                    break
                                end
                            end
                        end
                    end
                    if found
                        break
                    end
                end
            end
        end

        # check to configure data source
        if !found
            sources = HTTParty.get(
                getServerUrl() + "/api/sources/index", 
                    headers: { 'Accept' => '*/*', 
                               'Content-Type' => 'application/json', 
                               'Authorization' => 'Bearer ' + token.to_s }).parsed_response
            sources.each do |source|
                info = HTTParty.get(
                    getServerUrl() + "/api/sources/" + source["id"].to_s,  
                    headers: { 'Accept' => '*/*', 
                               'Content-Type' => 'application/json', 
                               'Authorization' => 'Bearer ' + token.to_s })
                if info.code == 200
                    if !source["configured"]
                        tmp = HTTParty.get(getServerUrl() + "/api/sources/" + source["id"].to_s,
                                headers: { 'Accept' => '*/*', 
                                           'Content-Type' => 'application/json', 
                                           'Authorization' => 'Bearer ' + token.to_s }).parsed_response
                        if tmp["assist_check"]
                            found = true
                            if I18n.locale.to_s == "de"
                                assist_text = "<p>Die Datenquelle '" + source["name"].to_s + "' ist noch nicht eingerichtet! Führe die folgenden Schritte zur Konfiguration durch:</p>"
                                assist_text += "<ol><li>wähle im Benutzermenü <span class='glyphicon glyphicon-user'></span> rechts oben den Eintrag 'Datenquellen'</li>"
                                assist_text += "<li>klicke bei der Datenquelle '" + source["name"].to_s + "' auf 'Konfigurieren' und folge den Anweisungen</li></ol>"
                            else
                                assist_text = "<p>The data source '" + source["name"].to_s + "' is not yet set up! Follow these steps for configuration:</p>"
                                assist_text += "<ol><li>open the user menu <span class='glyphicon glyphicon-user'></span> in the upper right corner and select 'Data Sources'</li>"
                                assist_text += "<li>click 'Configure' at the data source '" + source["name"].to_s + "' and follow the instructions</li></ol>"
                            end
                            assist_type = "configure_source"
                            assist_id = source["id"]
                            break
                        end
                    end
                end
            end
        end

        # check for inactive data source
        if !found
            inactive_sources = HTTParty.get(
                getServerUrl() + "/api/sources/inactive", 
                headers: { 'Accept' => '*/*', 
                           'Content-Type' => 'application/json', 
                           'Authorization' => 'Bearer ' + token.to_s }).parsed_response
            if (inactive_sources.count > 0)
                source_repo = inactive_sources.first
                found = true
                assist_text = source_repo["inactive_text"].to_s
                assist_type = "inactive_source"
                assist_id = source_repo["id"]
            end
        end

        # check for new plugins
        if !found
            installed_plugins = HTTParty.get(
                getServerUrl() + "/api/plugins/index", 
                    headers: { 'Accept' => '*/*', 
                               'Content-Type' => 'application/json', 
                               'Authorization' => 'Bearer ' + token.to_s }).parsed_response
            @avail = []
            @sam = []
            response = HTTParty.get("https://sam.oydapp.eu/api/plugins")
            if response.code == 200
                @sam = response.parsed_response
                @sam.each do |item| 
                    if item["language"] == I18n.locale.to_s && !@installed_plugins.pluck('identifier').include?(item["identifier"])
                        tmp = HTTParty.get(getServerUrl() + "/api/plugin/" + item["identifier"].to_s + "/assist", 
                                headers: { 'Accept' => '*/*', 
                                           'Content-Type' => 'application/json', 
                                           'Authorization' => 'Bearer ' + token.to_s }).parsed_response
                        if tmp["assist"]
                            found = true
                            if I18n.locale.to_s == "de"
                                assist_text = "<p>Die neue Erweiterung '" + item["name"].to_s + "' ist verfügbar! Führe die folgenden Schritte durch, um diese Erweiterung zu installieren:</p>"
                                assist_text += "<ol><li>wähle im Benutzermenü <span class='glyphicon glyphicon-user'></span> rechts oben den Eintrag 'Erweiterungen'</li>"
                                assist_text += "<li>klicke auf die Schaltfläche 'Erweiterung hinzufügen'</li>"
                                assist_text += "<li>wähle im angezeigten Dialog die Erweiterung '" + item["name"].to_s + "' aus und bestätige mit 'Abschicken'</li></ol>"
                            else
                                assist_text = "<p>The new plugin '" + item["name"].to_s + "' is available! Follow these steps to install the plugin:</p>"
                                assist_text += "<ol><li>open the user menu <span class='glyphicon glyphicon-user'></span> in the upper right corner and select 'Plugins'</li>"
                                assist_text += "<li>click on the 'Add Plugin' button</li>"
                                assist_text += "<li>in the dialog select the plugin '" + item["name"].to_s + "' and confirm with 'Submit'</li></ol>"
                            end
                            assist_type = "new_plugin"
                            assist_id = item["identifier"]
                            break
                        end
                    end
                end
            end
        end

        # otherwise: relax :-)
        if !found
            tmp = HTTParty.get(
                getServerUrl() + "/api/users/current", 
                    headers: { 'Accept' => '*/*', 
                               'Content-Type' => 'application/json', 
                               'Authorization' => 'Bearer ' + token.to_s }).parsed_response
            if tmp["assist_relax"].nil? | tmp["assist_relax"]
                found = true
                if I18n.locale.to_s == "de"
                    assist_text = "Du kannst dich zurücklehnen! Deine Daten werden automatisch gesammelt und du erhältst regelmäßig Nachrichten mit Ergebnissen.<br>Wenn du jetzt gleich ein wenig stöbern möchtest, klicke auf 'Fragen & Antworten' und entdecke Zusammenhänge in deinen Daten."
                else
                    assist_text = "You can relax! Your data will be collected automatically and you will receive regular news with results.<br> If you would like to browse a bit now, click on 'Questions & Answers' and discover insights in your data."
                end
                assist_type = "user_relax"
                assist_id = 0
            end
        end

        return found, assist_text, assist_type, assist_id
    end

end
