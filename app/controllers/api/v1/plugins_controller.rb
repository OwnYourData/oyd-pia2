module Api
    module V1
        class PluginsController < ApiController
            include PluginsHelper

            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def index
                if current_resource_owner.nil?
                    user_id = Doorkeeper::Application.where(
                        id: doorkeeper_token.application_id).first.owner_id
                else
                    user_id = current_resource_owner.id
                end
                render json: Doorkeeper::Application
                        .where('owner_id=' + user_id.to_s)
                        .select(:id, :identifier, :name, :oyd_version, :description, :language, :uid, :secret, :assist_update, :installation_hint),
                    status: 200
            end

            def create
                plugin_id = create_plugins(params, doorkeeper_token.resource_owner_id)
                if plugin_id < 0
                    render json: { error: "invalid plugin" },
                           status: 422
                else
                    # return plugin.id & Status 200
                    render json: { plugin_id: plugin_id }, status: 200
                end
            end

            def manifest_update
                if current_resource_owner.nil?
                    user_id = Doorkeeper::Application.where(
                        id: doorkeeper_token.application_id).first.owner_id
                else
                    user_id = current_resource_owner.id
                end

                plugin_id = params[:id]
                @plugin = Doorkeeper::Application.find(plugin_id)
                if @plugin.nil? || @plugin.owner_id != user_id
                    render json: { "error": "Permission denied" }, 
                           status: 403
                    return
                end

                old_version = false
                if @plugin.identifier == "en.ownyourdata"
                    plugin_lang = "en"
                    plugin_id = "oyd.base"
                    old_version = true
                elsif @plugin.identifier == "de.ownyourdata"
                    plugin_lang = "de"
                    plugin_id = "oyd.base"
                    old_version = true
                elsif @plugin.identifier == "en.oyd.location"
                    plugin_lang = "en"
                    plugin_id = "oyd.location"
                    old_version = true
                elsif @plugin.identifier == "de.oyd.location"
                    plugin_lang = "de"
                    plugin_id = "oyd.location"
                    old_version = true
                elsif @plugin.identifier == "en.oyd.allergy"
                    plugin_lang = "en"
                    plugin_id = "oyd.allergy"
                    old_version = true
                elsif @plugin.identifier == "de.oyd.allergy"
                    plugin_lang = "de"
                    plugin_id = "oyd.allergy"
                    old_version = true
                else
                    plugin_lang = @plugin.language
                    plugin_id = @plugin.identifier
                end
                if plugin_lang.to_s == ""
                    plugin_lang = "en"
                end

                new_item = nil
                @sam = HTTParty.get("https://sam.data-vault.eu/api/plugins").parsed_response
                @sam.each do |item| 
                    if (item["identifier"].to_s == plugin_id.to_s) && 
                        (item["language"].to_s == plugin_lang.to_s)
                            new_item = item.dup
                            break
                    end
                end

                if new_item.nil?
                    render json: { "error": "can't find update for " + plugin_id },
                           status: 400
                    return
                end

                # puts "update plugin " + @plugin.id.to_s + " (" + @plugin.identifier.to_s + ", v"  + @plugin.oyd_version.to_s + ") to " + new_item["identifier"].to_s + " (v" + new_item["version"].to_s + ", " + new_item["language"] + ")"

                # if (@plugin.identifier == "en.ownyourdata" or
                #     @plugin.identifier == "de.ownyourdata" or
                #     @plugin.identifier == "en.oyd.location" or
                #     @plugin.identifier == "de.oyd.location" or
                #     @plugin.identifier == "en.oyd.allergy" or
                #     @plugin.identifier == "de.oyd.allergy")

                        # delete plugin
                        # @plugin.destroy - don't remove plugin, otherwise a new key/secret is generaed and external plugins would require re-pairing

                        # reinstall plugin
                        response = HTTParty.get("https://sam.data-vault.eu/api/plugins/" + new_item["id"].to_s)
                        if response.code.to_s == "200"
                            pluginInfo = response.parsed_response rescue nil
                            retVal = create_plugin_helper(pluginInfo, user_id)

                            if retVal == -1
                                render json: { "error": "missing plugin info" },
                                       status: 400
                            elsif retVal == -2
                                render json: { "error": "invalid plugin" },
                                       status: 400
                            elsif retVal == -3
                                render json: { "error": "missing attributes" },
                                       status: 400
                            elsif retVal == -4
                                render json: { "error": "plugin already exists" },
                                       status: 400
                            elsif retVal == -5
                                render json: { "error": "unmet dependency" },
                                       status: 400
                            else
                                if old_version
                                    Doorkeeper::Application.find(params[:id]).destroy
                                end
                                render json: { "update": "via re-install",
                                               "id": retVal },
                                       status: 200
                            end
                        else
                            render json: { "error": "can't update " + plugin_id.to_s },
                                   status: 500
                        end
                # end

                # render json: { plugin_id: plugin_id }, status: 200
                #!!! include code to update plugin here
            end

            def show
                if current_resource_owner.nil?
                    render json: Doorkeeper::Application
                        .where(id: params[:id])
                        .select(:id, :name, :identifier, :uid, :secret, :oyd_version),
                        status: 200
                else
                    render json: Doorkeeper::Application
                        .where(owner_id: current_resource_owner.id, id: params[:id])
                        .select(:id, :name, :identifier, :uid, :secret, :oyd_version),
                        status: 200
                end
            end

            def show_identifier
                if current_resource_owner.nil?
                    render json: { "error": "Permission denied" }, 
                           status: 403
                else
                    render json: Doorkeeper::Application
                        .where(owner_id: current_resource_owner.id, identifier: params[:id])
                        .select(:id, :name, :identifier, :uid, :secret, :oyd_version),
                        status: 200
                end
            end

            def update
                if current_resource_owner.nil?
                    if doorkeeper_token.application_id.to_i != params[:id].to_i
                        render json: { "error": "Permission denied" }, 
                               status: 403
                        return
                    end
                else
                    if !Doorkeeper::Application.where(owner_id: current_resource_owner.id).pluck(:id)
                            .include?(params[:id].to_i)
                        render json: { "error": "Permission denied" }, 
                               status: 403
                        return
                    end
                end
                @plugin = Doorkeeper::Application.find(params[:id])
                if @plugin.nil?
                    render json: { "error": "plugin not found" }, 
                           status: 404
                else
                    update_params = params.except( *[ "format", 
                                                      "controller", 
                                                      "action",
                                                      "id",
                                                      "plugin" ] )
                    @plugin.update_attributes(update_params.permit(:name, :assist_update))
                    render json: { plugin_id: @plugin.id }, 
                           status: 200
                end
            end

            def current
                if !doorkeeper_token.application_id.nil?
                    @plugin = Doorkeeper::Application
                        .joins("INNER JOIN users ON users.id = oauth_applications.owner_id")
                        .where(id: doorkeeper_token.application_id)
                        .select(:id, :name, :identifier, :uid, :secret, :full_name, :email, "users.language as language", :email_notif)
                    if !@plugin.nil?
                        render json: @plugin.first,
                               status: 200
                    else
                        render json: { "error": "plugin not found" }, 
                               status: 404
                    end
                else
                    render json: { "error": "invalid request" }, 
                           status: 400
                end
            end

            def delete
                if current_resource_owner.nil?
                    if doorkeeper_token.application_id.to_i != params[:id].to_i
                        render json: { "error": "Permission denied" }, 
                               status: 403
                        return
                    end
                else
                    if !Doorkeeper::Application.where(owner_id: current_resource_owner.id).pluck(:id)
                            .include?(params[:id].to_i)
                        render json: { "error": "Permission denied" }, 
                               status: 403
                        return
                    end
                end
                Doorkeeper::Application.find(params[:id]).destroy
                render json: { "plugin_id": params[:id] }, 
                       status: 200
            end

            def assist
                if current_resource_owner.nil?
                    user_id = Doorkeeper::Application.find(doorkeeper_token.application_id) rescue nil
                    if user_id.nil?
                        render json: { "error": "invalid request" }, 
                               status: 400
                    end
                else
                    user_id = current_resource_owner.id
                end
                @pa = PluginAssist.where(user_id: user_id, identifier: params[:id].to_s)
                if @pa.count == 0
                    render json: { "assist": true }, 
                           status: 200
                else
                    render json: { "assist": @pa.first.assist }, 
                           status: 200
                end
            end

            def assist_update
                if current_resource_owner.nil?
                    user_id = Doorkeeper::Application.find(doorkeeper_token.application_id) rescue nil
                    if user_id.nil?
                        render json: { "error": "invalid request" }, 
                               status: 400
                    end
                else
                    user_id = current_resource_owner.id
                end
                @pa = PluginAssist.where(user_id: user_id, identifier: params[:id].to_s)
                if @pa.count > 0
                    @pa.destroy_all
                end
                if !params[:assist]
                    @pa_new = PluginAssist.new(
                        user_id: user_id,
                        identifier: params[:id],
                        assist: false )
                    if @pa_new.save
                        render json: { "assist-id": @pa_new.id, "assist": false }, 
                               status: 200
                    else
                        render json: { "error": @pa_new.errors.messages },
                               status: 400
                    end
                else
                    render json: { "assist": true }, 
                           status: 200
                end
            end

            def configure_DEPRECATED
                if current_resource_owner.nil?
                    if doorkeeper_token.application_id.to_i != params[:id].to_i
                        render json: { "error": "Permission denied" }, 
                               status: 403
                        return
                    end
                else
                    if !Doorkeeper::Application.where(owner_id: current_resource_owner.id).pluck(:id)
                            .include?(params[:id].to_i)
                        render json: { "error": "Permission denied" }, 
                               status: 403
                        return
                    end
                end
                @plugin = Doorkeeper::Application.find(params[:id])
                if !@plugin.nil?
                    plugin_config = JSON.parse(params[:config].to_s)
                    create_tasks(@plugin, JSON.parse(@plugin.tasks.to_s), plugin_config)
                    if !plugin_config["repos"].nil?
                        repos_config = JSON.parse(Base64.decode64(plugin_config["repos"]).to_s.gsub('=>', ':')) rescue []
                        params_config = plugin_config.except("utf8",
                                            "authenticity_token", 
                                            "plugin_id",
                                            "repos",
                                            "button",
                                            "controller",
                                            "action",
                                            "locale")
                        create_repos(@plugin, repos_config, params_config)
                    end
                    render json: { "plugin_id": params[:id] }, 
                           status: 200
                else
                    render json: { "error": "not found" },
                           status: 404
                end

            end
        end
    end
end
