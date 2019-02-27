module Api
    module V1
        class SourcesController < ApiController
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            include PluginsHelper
            include ApplicationHelper

            def index
                if current_resource_owner.nil?
                    user_id = Doorkeeper::Application.where(
                        id: doorkeeper_token.application_id).first.owner_id
                else
                    user_id = current_resource_owner.id
                end
                render json: OydSource
                        .joins("INNER JOIN oauth_applications ON oauth_applications.id = oyd_sources.plugin_id")
                        .where('oauth_applications.owner_id=' + user_id.to_s)
                        .select(:id, :identifier, :name, :configured, :description, :source_type),
                    status: 200
            end

            def show
                if !current_resource_owner.nil?
                    user_id = current_resource_owner.id
                    @oyd_source = OydSource.find(params[:id])
                    if @oyd_source.oauth_application.owner_id == user_id
                        count = 0
                        last = nil
                        @oyd_source.oyd_source_repos.each do |osr|
                            c = osr.repo.items.count
                            if !c.nil? && c > 0
                                count += c
                                if last.nil? || osr.repo.items.last.created_at > last
                                    last = osr.repo.items.last.created_at
                                end
                            end
                        end
                        render json: @oyd_source.attributes.merge(
                                    { "last": last, 
                                      "count": count }.stringify_keys),
                               status: 200
                    else
                        render json: { "error": "Permission denied" }, 
                               status: 403
                    end
                else
                    render json: { "error": "invalid request" }, 
                           status: 400
                end
            end

            def update
                if current_resource_owner.nil?
                    user_id = Doorkeeper::Application.where(
                        id: doorkeeper_token.application_id).first.owner_id
                else
                    user_id = current_resource_owner.id
                end
                @source = OydSource.find(params[:id]) rescue nil
                if @source.nil?
                    render json: { "error": "invalid request" }, 
                           status: 400
                else
                    if @source.oauth_application.owner_id != user_id
                        render json: { "error": "Permission denied" }, 
                               status: 403
                    else
                        if @source.update_attributes(params.permit(:name, :description, :assist_check, :inactive_check))
                            render json: { "source_id": @source.id },
                                   status: 200
                        else
                            render json: { "source_id": @source.id,
                                           "error": @source.errors.messages  }
                        end
                    end
                end
            end

            def configure
                if current_resource_owner.nil?
                    render json: { "error": "invalid request" }, 
                           status: 400
                    return
                else
                    user_id = current_resource_owner.id
                    @oyd_source = OydSource.find(params[:id])
                    if @oyd_source.oauth_application.owner_id != user_id
                        render json: { "error": "Permission denied" }, 
                               status: 403
                        return
                    else
                        @plugin = @oyd_source.oauth_application
                        paramsConfig = JSON.parse(params[:config])
                        itemConfig = JSON.parse(@oyd_source.config)["config"]
                        itemConfigValidatiaon = itemConfig['validation']
                        if !itemConfigValidatiaon.nil?
                            itemConfigValidatiaon.each do |group|
                                group.first.last.each do |field|
                                    case field.last
                                    when "float"
                                        if !float?(paramsConfig[field.first])
                                            render json: { "error": "invalid input"},
                                                   status: 400
                                            return
                                        end
                                    end
                                end
                            end
                        end
                        # merge params into itemConfig["fields"]
                        itemConfig = mergeConfigFields(itemConfig, params[:config])
                        itemConfigFields = itemConfig['fields']
                        itemConfigRepos = itemConfig['repos']
                        if !itemConfigRepos.nil?
                            itemConfig = parseConfigRepos(itemConfig)
                            config_values = { 
                                "repos": itemConfig['repos'],
                                "fields": itemConfig['fields'] 
                            }.to_json
                            @oyd_source.update_attributes(
                                config_values: config_values,
                                assist_check: true)

                            # create entries in oyd_source_repos
                            itemConfig['repos'].each do |repo|
                                repo_name = repo.last["name"]
                                repo_identifier = repo.last["identifier"]
                                repo_encryption = repo.last["encryption"]
                                repo_pubkey = ""
                                if repo_encryption.to_s.downcase == "true"
                                    @settings_repo = Repo.where(
                                        user_id: @plugin.owner_id,
                                        identifier: 'oyd.settings')
                                    if @settings_repo.count > 0
                                        repo_pubkey = @settings_repo.first.public_key
                                    end
                                end
                                @repo = Repo.where(user_id:    @plugin.owner_id,
                                                   identifier: repo_identifier)
                                if @repo.count == 0
                                    @repo = Repo.new(
                                        user_id: @plugin.owner_id,
                                        name: repo_name,
                                        identifier: repo_identifier,
                                        public_key: repo_pubkey)
                                    @repo.save
                                else
                                    @repo = @repo.first
                                end
                                @oyd_source_repo = OydSourceRepo.where(
                                    oyd_source_id: @oyd_source.id,
                                    repo_id: @repo.id)
                                if @oyd_source_repo.count == 0
                                    @oyd_source_repo = OydSourceRepo.new(
                                        oyd_source_id: @oyd_source.id,
                                        repo_id: @repo.id)
                                    @oyd_source_repo.save
                                end
                            end

                            # create entries in tasks
                            create_tasks(@plugin, 
                                         itemConfig['tasks'], 
                                         mergeParams(
                                            {"SOURCE_ID": @oyd_source.id}.stringify_keys,
                                             mergeParams(
                                                toParams(itemConfig['repos'], "REPO"),
                                                paramsConfig.to_json).to_json))

                            # create entries in answers
                            itemConfig['answers'].each do |answer|
                                OydAnswer.where(plugin_id: @plugin.id, identifier: answer['identifier']).destroy_all
                                @oyd_answer = OydAnswer.new(
                                    plugin_id: @plugin.id,
                                    name: answer['name'],
                                    short: answer['short'],
                                    identifier: answer['identifier'],
                                    category: answer['category'],
                                    info_url: answer['info_url'],
                                    repos: parseConfigArray(answer['repos'], 
                                                            toParams(itemConfig['repos'], "REPO")).to_s.gsub('=>', ':'),
                                    answer_order: answer['answer_order'],
                                    answer_view: Base64.strict_encode64(
                                        parseConfigValue(
                                            Base64.decode64(answer["answer_view"]),
                                            toParams(itemConfig['repos'], "REPO"))),
                                    answer_logic: Base64.strict_encode64(
                                        parseConfigValue(
                                            Base64.decode64(answer["answer_logic"]),
                                            toParams(itemConfig['repos'], "REPO"))))
                                @oyd_answer.save
                            end unless itemConfig['answers'].nil?

                            # create entries in reports
                            itemConfig['reports'].each do |report|
                                OydReport.where(plugin_id: @plugin.id, identifier: report['identifier']).destroy_all
                                @oyd_report = OydReport.new(
                                    plugin_id: @plugin.id,
                                    name: report['name'],
                                    identifier: report['identifier'],
                                    info_url: report['info_url'],
                                    repos: parseConfigArray(report['repos'], 
                                                            toParams(itemConfig['repos'], "REPO")).to_s.gsub('=>', ':'),
                                    data_prep: Base64.strict_encode64(
                                        parseConfigValue(
                                            Base64.decode64(report['data_prep']),
                                            toParams(itemConfig['repos'], "REPO"))),
                                    data_snippet: report['data_snippet'],
                                    report_view: Base64.strict_encode64(
                                        parseConfigValue(
                                            Base64.decode64(report['report_view']),
                                            toParams(itemConfig['repos'], "REPO"))),
                                    report_order: report['report_order'])
                                @oyd_report.save
                            end unless itemConfig['reports'].nil?
                        end
                        @oyd_source.update_attributes(
                            configured: true,
                            assist_check: true)

                        render json:  { "source_id": params[:id] }, 
                               status: 200
                    end
                end
            end

            def delete
                if !current_resource_owner.nil?
                    user_id = current_resource_owner.id
                    @oyd_source = OydSource.find(params[:id])
                    if @oyd_source.oauth_application.owner_id == user_id
                        @oyd_source.destroy
                        render json:  { "source_id": params[:id] }, 
                               status: 200
                    else
                        render json: { "error": "Permission denied" }, 
                               status: 403
                    end
                else
                    render json: { "error": "invalid request" }, 
                           status: 400
                end
            end

            def new_pile
                if !doorkeeper_token.application_id.nil?
                    @oyd_source = OydSource.find(params[:id])
                    if doorkeeper_token.application_id == @oyd_source.plugin_id
                        @pile = OydSourcePile.new(
                            oyd_source_id: @oyd_source.id,
                            content: params[:content].to_s,
                            email: params[:email].to_s,
                            signature: params[:signature].to_s,
                            verification: params[:verification].to_s )
                        if @pile.save
                            render json: { "oyd_source_pile_id": @pile.id },
                                   status: 200
                        else
                            render json: { "error": @pile.errors.messages },
                                   status: 500
                        end
                    else
                        render json: { "error": "Permission denied" }, 
                               status: 403
                    end
                else
                    render json: { "error": "invalid request" }, 
                           status: 400
                end
            end

            def last_pile
                if !doorkeeper_token.application_id.nil?
                    @oyd_source = OydSource.find(params[:id])
                    if doorkeeper_token.application_id == @oyd_source.plugin_id
                        if OydSourcePile.count > 0
                            render json: OydSourcePile.last.content.to_json,
                                   status: 200
                        else
                            render json: {},
                                   status: 200
                        end
                    else
                        render json: { "error": "Permission denied" }, 
                               status: 403
                    end
                else
                    render json: { "error": "invalid request" }, 
                           status: 400
                end
            end

            def show_pile
                pile_id = params[:id]
                @pile = OydSourcePile.find(pile_id)
                if !@pile.nil?
                    if doorkeeper_token.application_id.nil?
                        @app = Doorkeeper::Application.where(owner_id: doorkeeper_token.resource_owner_id).first rescue nil
                    else
                        @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                    end
                    if !@app.nil? and !@pile.oyd_source.nil?
                        if @pile.oyd_source.oauth_application.owner_id == @app.owner_id
                            render json: @pile.to_json,
                                   status: 200
                        else
                            render json: { "error": "Permission denied" }, 
                                   status: 403
                        end
                    else
                        render json: { "error": "invalid permission" }, 
                               status: 400
                    end
                else
                    render json: { "error": "invalid request" }, 
                           status: 400
                end
            end

            def inactive
                if current_resource_owner.nil?
                    user_id = Doorkeeper::Application.where(
                        id: doorkeeper_token.application_id).first.owner_id
                else
                    user_id = current_resource_owner.id
                end
                if !user_id.nil?
                    inactive_sources = []
                    @sources = OydSource.joins(
                        "INNER JOIN oauth_applications ON oauth_applications.id = oyd_sources.plugin_id").where(
                        'oauth_applications.owner_id=' + user_id.to_s)
                    @sources.each do |source|
                        if (!source["inactive_duration"].nil? and (source["inactive_check"].nil? or source["inactive_check"]))
                            count = 0
                            last = nil
                            source.oyd_source_repos.each do |osr|
                                c = osr.repo.items.count
                                if !c.nil? && c > 0
                                    count += c
                                    if (last.nil? or osr.repo.items.last.created_at > last)
                                        last = osr.repo.items.last.created_at
                                    end
                                end
                            end
                            if (last.nil? or last < (Time.now - source["inactive_duration"].to_i.days))
                                inactive_sources << source
                            end
                        end
                    end
                    render json: inactive_sources,
                           status: 200
                else
                    render json: { "error": "invalid request" }, 
                           status: 400
                end
            end
        end
    end
end
