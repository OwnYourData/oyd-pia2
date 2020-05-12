module Api
    module V1
        class UsersController < ApiController
            skip_before_action :doorkeeper_authorize!, only: [:name_by_token, :support]

            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            include PluginsHelper
            include ApplicationHelper
            include UsersHelper

            def create
                @user = User.new(
                    full_name: params[:name],
                    email: params[:email],
                    email_notif: true,
                    assist_relax: true,
                    language: params[:language],
                    frontend_url: params[:frontend_url] || ENV['VAULT_URL'].to_s)
                if @user.save
                    if params[:language].downcase == "de"
                        msg = "Ein Email zur Aktivierung des Kontos wurde verschickt. Bitte prüfe dein Email Postfach und folge den Anweisungen die Erstellung des Datentresors abzuschließen."
                    else
                        msg = "An email to activate the account has been sent. Please check your emails and follow the instructions to complete the data vault setup."
                    end
                    render json: { "user-id": @user.id, "message": msg }, 
                           status: 200
                else
                    case @user.errors.full_messages.first
                    when "Email has already been taken"
                        if params[:language].downcase == "de"
                            message = "Die angegebene Emailadresse wird bereits verwendet. Bitte korrigiere deine Eingabe!"
                        else
                            message = "The specified email address is already in use. Please correct your input!"
                        end
                    when "Email is invalid"
                        if params[:language].downcase == "de"
                            message = "Die angegebene Emailadresse ist ungültig. Bitte korrigiere deine Eingabe!"
                        else
                            message = "The specified email address is invalid. Please correct your input!"
                        end
                    else
                        if params[:language].downcase == "de"
                            message = "Ein unerwarteter Fehler ist aufgetreten. Versuche es später nochmal."
                        else
                            message = "An unexpected error occurred. Try again later."
                        end
                    end
                    render json: { "error": @user.errors.full_messages, "message": message }, 
                           status: 400
                end                
            end

            def confirm
                require 'rbnacl'
                require 'bcrypt'
                require 'securerandom'

                @user = User.where(confirmation_token: params[:token]).first
                if @user.nil?
                    render json: { "error": "invalid token" }, status: 422
                else
                    if @user.update(
                            full_name: params[:full_name],
                            password: params[:password],
                            password_confirmation: params[:password_confirmation],
                            recovery_password: params[:recovery_password],
                            recovery_password_confirmation: params[:recovery_password_confirmation],
                            recovery_password_digest: BCrypt::Password.create(params[:recovery_password]))
                        if @user.valid? && @user.password_match?
                            @user.confirm
                            @user.update(confirmation_token: nil)

                            # use password as seed for private/public key generation
                            keyStr = SecureRandom.base64(64)
                            keyHash = RbNaCl::Hash.sha256(keyStr.force_encoding('ASCII-8BIT'))
                            unknown_private_key = RbNaCl::PrivateKey.new(keyHash)
                            public_key = unknown_private_key.public_key.to_s.unpack('H*')[0]
                            @repo = Repo.where(user_id: @user.id,
                                               identifier: 'oyd.settings')
                            if @repo.count == 0
                                settings_name = "Settings"
                                if @user.language == "de"
                                    settings_name = "Einstellungen"
                                end
                                @repo = Repo.new(user_id: @user.id,
                                                 name: settings_name,
                                                 identifier: 'oyd.settings',
                                                 public_key: public_key)
                                retVal = @repo.save
                                @repo.items.new(value: '{"value":0}').save
                            end
                            @user.update(
                                password_key: key_encrypt(keyStr, params[:password]), 
                                recovery_password_key: key_encrypt(keyStr, params[:recovery_password]))

                            # install first beta setup !!! fix me
                            # https://sam-en.data-vault.eu/api/plugins/1
                            sam_url = "https://sam.data-vault.eu/api/plugins"
                            if @user.language == 'de'
                                response = HTTParty.get(sam_url + "?identifier=oyd.base&lang=de")
                                pluginInfo = response.parsed_response rescue nil
                                plugin_id = create_plugin_helper(pluginInfo, @user.id)

                                response = HTTParty.get(sam_url + "?identifier=oyd.location&lang=de")
                                pluginInfo = response.parsed_response rescue nil
                                plugin_id = create_plugin_helper(pluginInfo, @user.id)

                                response = HTTParty.get(sam_url + "?identifier=oyd.allergy&lang=de")
                                pluginInfo = response.parsed_response rescue nil
                                plugin_id = create_plugin_helper(pluginInfo, @user.id)

                            else 
                                response = HTTParty.get(sam_url + "?identifier=oyd.base&lang=en")
                                pluginInfo = response.parsed_response rescue nil
                                plugin_id = create_plugin_helper(pluginInfo, @user.id)

                                response = HTTParty.get(sam_url + "?identifier=oyd.location&lang=en")
                                pluginInfo = response.parsed_response rescue nil
                                plugin_id = create_plugin_helper(pluginInfo, @user.id)

                                response = HTTParty.get(sam_url + "?identifier=oyd.allergy&lang=en")
                                pluginInfo = response.parsed_response rescue nil
                                plugin_id = create_plugin_helper(pluginInfo, @user.id)

                            end

                            render json: { "user-id": @user.id }, 
                                   status: 200
                        else
                            render json: { "error":  @user.errors.full_messages.first }, 
                                   status: 422
                        end
                    else
                        render json: { "error": @user.errors.full_messages }, 
                               status: 422
                    end
                end
            end

            def current
                if current_resource_owner.nil?
                    user_id = Doorkeeper::Application.where(
                        id: doorkeeper_token.application_id).first.owner_id
                else
                    user_id = current_resource_owner.id
                end
                render json: User.find(user_id),
                       status: 200
            end

            def show
                if current_resource_owner.nil?
                    render json: { "error": "invalid request"},
                           status: 422
                else
                    render json: current_resource_owner.attributes, 
                           status: 200
                end
            end

            def do_remember
                @user = User.find(params[:user_id])
                if !@user.nil?
                    if @user.update_attributes(remember_digest: User.digest(params[:remember_token]))
                        render json: @user.attributes,
                               status: 200
                    else
                        render json: { messages: @user.errors.messages },
                               status: 500
                    end
                else
                    render json: { "error": "invalid request"},
                           status: 422
                end
            end

            def remember
                @user = User.find(params[:user_id])
                if @user
                    if BCrypt::Password.new(@user.remember_digest).is_password?(params[:token])
                        access_token = Doorkeeper::AccessToken.create!(
                            :application_id => Doorkeeper::Application.first.id, 
                            :resource_owner_id => @user.id)
                        render json: { "token": access_token.token.to_s },
                               status: 200
                    else
                        render json: { "error": "invalid remember token" },
                               status: 400
                    end
                else
                    render json: { "error": "unknown user" },
                           status: 400
                end
            end

            def forget
                @user = User.find(params[:user_id])
                if !@user.nil?
                    if @user.update_attributes(remember_digest: nil)
                        render json: @user.attributes,
                               status: 200
                    else
                        render json: { messages: @user.errors.messages },
                               status: 500
                    end
                else
                    render json: { "error": "invalid request"},
                           status: 422
                end
            end

            def update
                if current_resource_owner.nil?
                    user_id = Doorkeeper::Application.where(
                        id: doorkeeper_token.application_id).first.owner_id
                else
                    user_id = current_resource_owner.id
                end
                @user = User.find(user_id)
                if !@user.nil?
                    if @user.update_attributes(params.permit(:full_name, :email_notif, :language, :assist_relax))
                            # full_name: params[:name].to_s,
                            # email_notif: (params[:notif].to_s.downcase == "true"),
                            # language: params[:lang].to_s)
                        render json: @user.attributes,
                               status: 200
                    else
                        render json: { messages: @user.errors.messages },
                               status: 500
                    end
                else
                    render json: { "error": "invalid request"},
                           status: 422
                end
            end

            def update_pwd
                if current_resource_owner.nil?
                    user_id = Doorkeeper::Application.where(
                        id: doorkeeper_token.application_id).first.owner_id
                else
                    user_id = current_resource_owner.id
                end
                @user = User.find(user_id)
                if !@user.nil?
                    if @user.valid_password?(params[:old_password])
                        if @user.update(
                                password: params[:password],
                                password_confirmation: params[:password_confirmation])
                            if @user.valid? && @user.password_only_match?
                                # update master key
                                original_key = decrypt_message(@user.password_key, params[:old_password])
                                @user.update(
                                    password_key: key_encrypt(original_key, params[:password]))

                                render json: { "user-id": @user.id }, 
                                       status: 200
                            else
                                @user.update(
                                    password: params[:old_password],
                                    password_confirmation: params[:old_password])
                                render json: { "error":  @user.errors.full_messages.first }, 
                                       status: 422
                            end
                        else
                            render json: { "error": @user.errors.full_messages }, 
                                   status: 422
                        end
                    else
                        render json: { "error": "invalid password" }, 
                               status: 422
                    end
                else
                    render json: { "error": "invalid request"},
                           status: 422
                end
            end

            def update_recv_pwd
                if current_resource_owner.nil?
                    user_id = Doorkeeper::Application.where(
                        id: doorkeeper_token.application_id).first.owner_id
                else
                    user_id = current_resource_owner.id
                end
                @user = User.find(user_id)
                if !@user.nil?
                    if @user.valid_password?(params[:curr_password])
                        if (params[:recovery_password] == params[:recovery_password_confirmation]) &&
                                (!params[:recovery_password].blank?)     &&
                                (params[:recovery_password].to_s.length > 5) &&
                                (params[:recovery_password] != params[:curr_password])
                            # update master key
                            original_key = decrypt_message(@user.password_key, params[:curr_password])
                            @user.update(
                                recovery_password: params[:recovery_password],
                                recovery_password_confirmation: params[:recovery_password_confirmation],
                                recovery_password_key: key_encrypt(original_key, params[:recovery_password]))
                            render json: { "user-id": @user.id }, 
                                   status: 200
                        else
                            render json: { "error":  "invalid recovery password" }, 
                                   status: 422
                        end
                    else
                        render json: { "error": "invalid password" }, 
                               status: 422
                    end
                else
                    render json: { "error": "invalid request"},
                           status: 422
                end    
            end

            def reset_password
                @user = User.find_by_email(params[:email].to_s)
                token = SecureRandom.urlsafe_base64
                if @user
                    if @user.update_attributes(
                        reset_digest: User.digest(token),
                        reset_sent_at: Time.zone.now)

                        OydMailer.with(user: @user, token: token).password_reset.deliver_now
                        render json: { "id": @user.id },
                               status: 200
                    else
                        render json: { "error": "update problems" },
                               status: 400
                    end
                else
                    render json: { "error": "invalid email" },
                           status: 400
                end
            end

            def perform_password_reset
                # Validations
                # 1) is the token valid and within time?
                # 2) is the password empty?
                # 3) are password and password_confirmation identical
                # 4) do the fulfill the minimum password requirements
                # 5) valid Recovery Password

                # 1) is the token valid and within time?
                @user = User.find_by_email(params[:email].to_s)
                if !@user
                    render json: { "error": "invalid request" },
                           status: 404
                    return
                end
                if !BCrypt::Password.new(@user.reset_digest).is_password?(params[:token].to_s)
                    render json: { "error": "invalid request token" },
                           status: 400
                    return
                end
                if @user.reset_sent_at < 2.hours.ago
                    render json: { "error": "expired token" },
                           status: 400
                    return
                end

                # 2) is the password empty?
                if params[:password].empty?
                    render json: { "error": "Password can't be blank" },
                           status: 400
                    return
                end

                # 3) are password and password_confirmation identical
                if params[:password] != params[:password_confirmation]
                    render json: { "error": "Password confirmation does not match password" },
                           status: 400
                    return
                end

                # 4) do the fulfill the minimum password requirements
                if params[:password].to_s.length < 6
                    render json: { "error": "Password too short" },
                           status: 400
                    return
                end

                # 5) valid Recovery Password
                if !Devise::Encryptor.compare(@user.class, 
                                              @user.recovery_password_digest, 
                                              params[:recovery_password])
                    render json: { "error": "Invalid recovery password" },
                           status: 400
                    return
                end

                # actually update password
                if !@user.update(
                        password: params[:password],
                        password_confirmation: params[:password_confirmation])
                    render json: { "error": "Invalid password" },
                           status: 400
                    return
                end

                if @user.valid? && @user.password_only_match?
                    # update master key
                    original_key = decrypt_message(@user.recovery_password_key, params[:recovery_password])
                    @user.update(
                        password_key: key_encrypt(original_key, params[:password]),
                        reset_digest: nil )

                    render json: { "user-id": @user.id }, 
                           status: 200
                else
                    render json: { "error": "Invalid update" },
                           status: 400
                    return
                end
            end

            def name_by_token
                @user = User.find_by_confirmation_token(params[:id])
                if @user.nil?
                    render json: { message: "user not found" }, 
                           status: 404
                else
                    render json: { email: @user.email, 
                                   full_name: @user.full_name }, 
                           status: 200
                end
            end

            def record_count
                if current_resource_owner.nil?
                    user_id = Doorkeeper::Application.where(
                        id: doorkeeper_token.application_id).first.owner_id
                else
                    user_id = current_resource_owner.id
                end
                @user = User.find(user_id)
                if @user.nil?
                    render json: { "error": "invalid token" }, status: 422
                else
                    cnt = Item.where(repo_id: Repo.where(user_id: user_id).pluck(:id)).count
                    render json: { "count": cnt }, status: 200
                end
            end

            def access_count
                if current_resource_owner.nil?
                    render json: { "error": "invalid request"},
                           status: 422
                    return
                else
                    user_id = current_resource_owner.id
                end
                @user = User.find(user_id)
                if @user.nil?
                    render json: { "error": "invalid token" }, status: 422
                else
                    new_cnt = OydAccess.where(
                        "created_at >= ?", 14.days.ago.utc).where(
                        user_id: user_id,
                        operation: PermType::WRITE).count
                    read_cnt = OydAccess.where(
                        "created_at >= ?", 14.days.ago.utc).where(
                        user_id: user_id,
                        operation: PermType::READ).count
                    update_cnt = OydAccess.where(
                        "created_at >= ?", 14.days.ago.utc).where(
                        user_id: user_id,
                        operation: PermType::UPDATE).count
                    delete_cnt = OydAccess.where(
                        "created_at >= ?", 14.days.ago.utc).where(
                        user_id: user_id,
                        operation: PermType::DELETE).count

                    render json: { "create": new_cnt,
                                   "read": read_cnt,
                                   "update": update_cnt,
                                   "delete": delete_cnt }, 
                           status: 200
                end
            end

            def archive
                if current_resource_owner.nil?
                    user_id = Doorkeeper::Application.where(
                        id: doorkeeper_token.application_id).first.owner_id
                else
                    user_id = current_resource_owner.id
                end
                @user = User.find(user_id)
                if !@user.nil?
                    password = params[:password]
                    private_key = decrypt_message(@user.password_key, password)
                    data = []
                    @user.repos.each do |repo|
                        repoHash = Hash.new()
                        if repo.public_key == ""
                            repoHash[repo.name] = repo.items.map{ |item| JSON.parse(item.value) rescue {} }
                        else
                            val = JSON.parse(repo.items.first.value) rescue nil
                            if !val.nil?
                                if val["version"] == "0.4"
                                    repoHash[repo.name] = repo.items.map{ |item| 
                                        JSON.parse(decrypt_message(item.value, private_key)) rescue {} }
                                else
                                    repoHash[repo.name] = repo.items.map{ |item| JSON.parse(item.value) rescue {} }
                                end
                            else
                                repoHash[repo.name] = repo.items.map{ |item| JSON.parse(item.value) rescue {} }
                            end
                        end
                        data << repoHash
                    end
                    render json: { "user_id": @user.id,
                                   "name:": @user.full_name,
                                   "email": @user.email,
                                   "data": data},
                           status: 200
                else
                    render json: { "error": "invalid request"},
                           status: 422
                end    
            end

            def delete
                if current_resource_owner.nil?
                    user_id = Doorkeeper::Application.where(
                        id: doorkeeper_token.application_id).first.owner_id
                else
                    user_id = current_resource_owner.id
                end
                @user = User.find(user_id)
                if !@user.nil?
                    password = params[:password]
                    private_key = decrypt_message(@user.password_key, password)
                    if private_key.to_s == ""
                        render json: { "error": "invalid request"},
                               status: 422
                    else
                        id = @user.id
                        puts "delete user " + id.to_s
                        @user.destroy
                        render json: { "user_id": id },
                               status: 200
                    end
                else
                    render json: { "error": "invalid request"},
                           status: 422
                end    
            end

            def statistics
                if current_resource_owner.nil?
                    user_id = Doorkeeper::Application.where(
                        id: doorkeeper_token.application_id).first.owner_id
                else
                    user_id = current_resource_owner.id
                end
                @user = User.find(user_id)
                if !@user.nil?

                    # count users
                    user_count = User.count

                    # count records
                    record_count = 0
                    @user.repos.each do |repo|
                        record_count += repo.items.where('created_at >= ?', 1.week.ago).count
                    end

                    # count sources
                    source_count = 0
                    @all_sources = OydSource.where(plugin_id: @user.oauth_applications.pluck(:id))
                    @all_sources.each do |source|
                        last = nil
                        source.oyd_source_repos.each do |osr|
                            c = osr.repo.items.count
                            if !c.nil? && c > 0
                                if last.nil? || osr.repo.items.last.created_at > last
                                    last = osr.repo.items.last.created_at
                                end
                            end
                        end
                        if !last.nil? and last > 1.week.ago
                            source_count += 1
                        end
                    end

                    # calc rank
                    @user.update_attributes(last_item_count: record_count)
                    rank = User.pluck(:last_item_count).reject { |e| e.to_s.empty? }.sort.reverse.find_index { |e| e.to_s.match( /^#{record_count}$/ ) }
                    if rank.nil?
                        rank = user_count
                    else
                        rank += 1
                    end

                    # exist hints
                    hints_available = false
                    @show_assistant, @assist_text, @assist_type, @assist_id = oyd_assistant(doorkeeper_token.token.to_s)
                    if (@show_assistant and @assist_type != "user_relax")
                        hints_available = true
                    end

                    # are sources inactive?
                    sources_inactive = (@all_sources.count == source_count)

                    render json: { "records": record_count,
                                   "sources": source_count,
                                   "rank": rank,
                                   "users": user_count,
                                   "hints": hints_available,
                                   "inactive": sources_inactive },
                           status: 200
                else
                    render json: { "error": "invalid request"},
                           status: 422
                end    
            end

            def hints
                if current_resource_owner.nil?
                    user_id = Doorkeeper::Application.where(
                        id: doorkeeper_token.application_id).first.owner_id
                else
                    user_id = current_resource_owner.id
                end
                @user = User.find(user_id)
                if !@user.nil?
                    retVal = []

                    # check for updated plugin version
                    @plugins = @user.oauth_applications
                    @sam = []
                    response = HTTParty.get("https://sam.data-vault.eu/api/plugins")
                    if response.code == 200
                        @sam = response.parsed_response
                    end
                    @plugins.each do |plugin|
                        if plugin["oyd_version"].to_s == ""
                            if plugin["assist_update"].nil? or plugin["assist_update"]
                                if params[:lang].to_s == "de"
                                    retVal << "für die Erweiterung '" + plugin["name"].to_s + "' gibt es eine neue Version - <a href='" + ENV['VAULT_URL'].to_s + "/de/plugins'>hier aktualisieren</a>"
                                else
                                    retVal << "for the plugin '" + plugin["name"].to_s + "' is a new version available - <a href='" + ENV['VAULT_URL'].to_s + "/en/plugins'>update here</a>"
                                end
                            end
                        else
                            @sam.each do |item|
                                if (plugin["identifier"].to_s == item["identifier"].to_s) and ((plugin["language"].to_s == item["language"].to_s) or plugin["language"].to_s == "")
                                    if (plugin["oyd_version"].to_s != item["version"].to_s)
                                        if plugin["assist_update"].nil? or plugin["assist_update"]
                                            if params[:lang].to_s == "de"
                                                retVal << "für die Erweiterung '" + plugin["name"].to_s + "' gibt es eine neue Version - <a href='" + ENV['VAULT_URL'].to_s + "/de/plugins'>hier aktualisieren</a>"
                                            else
                                                retVal << "for the plugin '" + plugin["name"].to_s + "' is a new version available - <a href='" + ENV['VAULT_URL'].to_s + "/en/plugins'>update here</a>"
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    # check if data source needs configuration
                    @sources = OydSource.where(plugin_id: @user.oauth_applications.pluck(:id))
                    @sources.each do |source|
                        if !source["configured"]
                            if source["assist_check"].nil? or source["assist_check"]
                                if params[:lang].to_s == "de"
                                    retVal << "die Datenquelle '" + source["name"].to_s + "' ist noch nicht konfiguriert - <a href='" + ENV['VAULT_URL'].to_s + "/de/sources'>hier einrichten</a>"
                                else
                                    retVal << "the data source '" + source["name"].to_s + "' is not yet configured - <a href='" + ENV['VAULT_URL'].to_s + "/en/sources'>set it up here</a>"
                                end
                            end
                        end
                    end

                    # check for new plugin
                    @sam.each do |item| 
                        if item["language"] == params[:lang].to_s and !@plugins.pluck('identifier').include?(item["identifier"])
                            if PluginAssist.where(user_id: @user.id, identifier: item["identifier"].to_s, assist: false).count == 0
                                exec = true
                                inst_plugins = @plugins.pluck(:identifier)
                                if item["identifier"] == "oyd.base" and inst_plugins.include?("en.ownyourdata")
                                    exec = false
                                end
                                if item["identifier"] == "oyd.allergy" and (inst_plugins.include?("en.oyd.allergy") or inst_plugins.include?("de.oyd.allergy"))
                                    exec = false
                                end
                                if item["identifier"] == "oyd.location" and (inst_plugins.include?("en.oyd.location") or inst_plugins.include?("de.oyd.location"))
                                    exec = false
                                end
                                if exec
                                    if params[:lang].to_s == "de"
                                        retVal << "die neue Erweiterung '" + item["name"].to_s + "' ist verfügbar - <a href='" + ENV['VAULT_URL'].to_s + "/de/plugins'>hier installieren</a>"
                                    else
                                        retVal << "the new plugin '" + item["name"].to_s + "' is available - <a href='" + ENV['VAULT_URL'].to_s + "/en/plugins'>install here</a>"
                                    end
                                end
                            end
                        end
                    end

                    render json: retVal,
                           status: 200

                else
                    render json: { "error": "invalid request"},
                           status: 422
                end    
            end

            def inactive_sources
                if current_resource_owner.nil?
                    user_id = Doorkeeper::Application.where(
                        id: doorkeeper_token.application_id).first.owner_id
                else
                    user_id = current_resource_owner.id
                end
                @user = User.find(user_id)
                if !@user.nil?
                    retVal = []
                    OydSource.where(plugin_id: @user.oauth_applications.pluck(:id)).each do |source|
                        last = nil
                        source.oyd_source_repos.each do |osr|
                            c = osr.repo.items.count
                            if !c.nil? && c > 0
                                if last.nil? || osr.repo.items.last.created_at > last
                                    last = osr.repo.items.last.created_at
                                end
                            end
                        end
                        if last.nil? or last < 1.week.ago
                            retVal << source["inactive_text"]
                        end
                    end

                    render json: retVal,
                           status: 200
                else
                    render json: { "error": "invalid request"},
                           status: 422
                end    

            end

            def app_support
                if current_resource_owner.nil?
                    if doorkeeper_token.nil?
                        render json: { "error": "unauthorized"},
                               status: 401
                    else
                        user_id = Doorkeeper::Application.where(
                            id: doorkeeper_token.application_id).first.owner_id
                    end
                else
                    user_id = current_resource_owner.id
                end
                @user = User.find(user_id)
                if !@user.nil?
                    if @user.update_attributes(
                            app_nonce: params[:nonce],
                            app_cipher: params[:cipher])
                        render json: { "support": true },
                               status: 200
                    else
                        render json: { "error": "update failed"},
                               status: 500
                    end
                else
                    render json: { "error": "invalid request"},
                           status: 422
                end    
            end

            def support
                @user = User.find_by_app_nonce(params[:nonce])
                if @user.nil?
                    render json: { "error": "unknown nonce" },
                           status: 404
                else
                    render json: { "email": @user.email,
                                   "cipher": @user.app_cipher },
                           status: 200
                end
            end
        end
    end
end
