module PluginsHelper
    def create_plugins(params, user_id)
        require 'httparty'
        require 'base64'

        # validation ================
        # get manifest
        if(params[:manifest].nil?)
            # download plugin infos from SAM (source_url)
            response = HTTParty.get(params[:source_url])
            pluginInfo = response.parsed_response rescue nil
        else
            pluginInfo = JSON.parse(Base64.decode64(params[:manifest])) rescue nil
        end
        create_plugin_helper(pluginInfo, user_id)
    end

    def create_plugin_helper(pluginInfo, user_id)
        pluginInfo = pluginInfo.deep_stringify_keys
        if pluginInfo.nil?
            return -1 # missing plugin info
        end

        if !pluginInfo.is_a?(Hash)
            return -2 #invalid plugin
        end

        # check if valid attributes
        if pluginInfo['identifier'].nil? |
           pluginInfo['version'].nil?
                   return -3 # missing attributes
        end

        # check if plugin alread exists
        @plugin = Doorkeeper::Application.where(
            owner_id: user_id,
            identifier: pluginInfo['identifier'])
        # if plugin exists -> overwrite!
        # if !(@plugin.nil? || @plugin.count == 0)
        #     return -4 # plugin exists
        # end

        # check if requires statements are fulfilled
        if !pluginInfo['sources'].nil?
            pluginInfo['sources'].each do |source|
                if !source['requires'].nil?
                    source['requires'].each do |req|
                        @tmp = Doorkeeper::Application.where(
                            owner_id: user_id,
                            identifier: req['plugin'].to_s)
                        if @tmp.nil? || @tmp.count == 0
                            return -5 # unmet dependency
                        end
                    end
                end
            end
        end

        # create entry in OauthApplication ===============
        @plugin = Doorkeeper::Application.where(
            owner_id: user_id,
            identifier: pluginInfo['identifier'])
        if @plugin.nil? || @plugin.count == 0
            @plugin = Doorkeeper::Application.new(
                owner_id: user_id,
                owner_type: 'User',
                name: pluginInfo['name'],
                identifier: pluginInfo['identifier'], 
                oyd_version: pluginInfo['version'],
                language: pluginInfo['language'],
                assist_update: true,
                description: pluginInfo['description'],
                redirect_uri: "https://localhost:3000/oauth/callback" )
            retVal = @plugin.save
        else
            @plugin = @plugin.first
            @plugin.update_attributes(
                owner_type: 'User',
                name: pluginInfo['name'],
                oyd_version: pluginInfo['version'],
                language: pluginInfo['language'],
                assist_update: true,
                description: pluginInfo['description'],
                redirect_uri: "https://localhost:3000/oauth/callback" )
        end

        # create entries in Permission ===============
        @plugin.permissions.destroy_all
        pluginInfo['permissions'].each do |item| 
            part = item.split(':')
            pt = nil
            case part[1]
            when 'read'
                pt = PermType::READ
            when 'write'
                pt = PermType::WRITE
            when 'update'
                pt = PermType::UPDATE
            when 'delete'
                pt = PermType::DELETE
            end
            if part[1] == '*'
                @permission = Permission.new(
                    plugin_id: @plugin.id,
                    repo_identifier: part[0],
                    perm_type: PermType::READ,
                    perm_allow: true)
                @permission.save
                @permission = Permission.new(
                    plugin_id: @plugin.id,
                    repo_identifier: part[0],
                    perm_type: PermType::WRITE,
                    perm_allow: true)
                @permission.save
                @permission = Permission.new(
                    plugin_id: @plugin.id,
                    repo_identifier: part[0],
                    perm_type: PermType::UPDATE,
                    perm_allow: true)
                @permission.save
                @permission = Permission.new(
                    plugin_id: @plugin.id,
                    repo_identifier: part[0],
                    perm_type: PermType::DELETE,
                    perm_allow: true)
                @permission.save
            else
                @permission = Permission.new(
                    plugin_id: @plugin.id,
                    repo_identifier: part[0],
                    perm_type: pt,
                    perm_allow: true)
                @permission.save
            end
        end unless pluginInfo['permissions'].nil?

        # create data sources ===============
        # get list of existing data sources
        @existing_sources = OydSource
            .joins("INNER JOIN oauth_applications ON oauth_applications.id = oyd_sources.plugin_id")
            .where('oauth_applications.owner_id=' + @plugin.owner_id.to_s)
            .pluck(:identifier)
            .uniq

        pluginInfo['sources'].each do |item|
            # check if identifier alreay exists for this user
            # only if not create new!

            if !@existing_sources.include? item['identifier'] 
                # create entry in oyd_sources
                @oyd_source = OydSource.new(
                    plugin_id: @plugin.id,
                    name: item['name'],
                    identifier: item['identifier'],
                    description: item['description'],
                    source_type: item['type'],
                    inactive_duration: item['inactive_duration'],
                    inactive_text: item['inactive_text'],
                    inactive_check: true,
                    configured: true,
                    assist_check: true,
                    config: item.to_s.gsub('=>', ':'))
                @oyd_source.save

                # is there anything to configure?
                if !item['config'].nil?
                    itemConfig = item['config']
                    # does it require any user fields?
                    if !itemConfig['fields'].nil? && itemConfig['fields'].length == 0
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
                                if repo_encryption.downcase == "true"
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
                                @oyd_source_repo = OydSourceRepo.new(
                                    oyd_source_id: @oyd_source.id,
                                    repo_id: @repo.id)
                                @oyd_source_repo.save
                            end

                            # create entries in tasks
                            create_tasks(@plugin, itemConfig['tasks'], 
                                mergeParams(
                                    { "SOURCE_ID": @oyd_source.id }.stringify_keys,
                                    toParams(itemConfig['repos'], "REPO").to_s.gsub("=>", ":")))

                            # create entries in answers
                            itemConfig['answers'].each do |answer|
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
                    else
                        # requires config in data soure
                        @oyd_source.update_attributes(
                            configured: false,
                            assist_check: true)
                    end
                end
            end
        end unless pluginInfo['sources'].nil?

        # create views =================
        pluginInfo['views'].each do |view|
            # check if identifier exists in PluginDetail: create/update
            @pluginDetail = PluginDetail.find_by_identifier(view['identifier'])
            if @pluginDetail.nil?
                @pluginDetail = PluginDetail.new(
                    identifier: view['identifier'],
                    description: view['description'],
                    picture: view['picture'])
                @pluginDetail.save
            else
                @pluginDetail.update_attributes(
                    description: view['description'],
                    picture: view['picture'])
            end

            # create entries in OydView
            if OydView.where(plugin_id: @plugin.id,
                             identifier: view['identifier']).count == 0
                @view = OydView.new(
                    plugin_id: @plugin.id,
                    plugin_detail_id: @pluginDetail.id,
                    name: view['name'],
                    identifier: view['identifier'],
                    url: view['url'],
                    view_type: 'oyd_view')
                retVal = @view.save
            end
        end unless pluginInfo['views'].nil?

        # create mobiles
        pluginInfo['mobiles'].each do |view|
            # check if identifier exists in PluginDetail: create/update
            @pluginDetail = PluginDetail.find_by_identifier(view['identifier'])
            if @pluginDetail.nil?
                @pluginDetail = PluginDetail.new(
                    identifier: view['identifier'],
                    description: view['description'],
                    picture: view['picture'],
                    info_url: view['infourl'])
                @pluginDetail.save
            end

            # create entries in OydView
            if OydView.where(plugin_id: @plugin.id,
                             identifier: view['identifier']).count == 0
                @view = OydView.new(
                    plugin_id: @plugin.id,
                    plugin_detail_id: @pluginDetail.id,
                    name: view['name'],
                    identifier: view['identifier'],
                    url: view['url'],
                    view_type: 'oyd_mobileview')
                @view.save
            end
        end unless pluginInfo['mobiles'].nil?

        # create tasks
        create_tasks(@plugin, pluginInfo['tasks'], params[:config])

        # create answer snippets
        pluginInfo['answers'].each do |answer|
            @oyd_answer = OydAnswer.new(
                plugin_id: @plugin.id,
                name: answer['name'],
                short: answer['short'],
                identifier: answer['identifier'],
                category: answer['category'],
                info_url: answer['info_url'],
                repos: answer['repos'].to_s.gsub('=>', ':'),
                answer_order: answer['answer_order'],
                answer_view: answer['answer_view'],
                answer_logic: answer['answer_logic'])
            @oyd_answer.save
        end unless pluginInfo['answers'].nil?

        # create report snippets
        pluginInfo['reports'].each do |report|
            @oyd_report = OydReport.new(
                plugin_id: @plugin.id,
                name: report['name'],
                identifier: report['identifier'],
                info_url: report['info_url'],
                repos: report['repos'].to_s.gsub('=>', ':'),
                data_prep: report['data_prep'],
                data_snippet: report['data_snippet'],
                report_view: report['report_view'],
                report_order: report['report_order'])
            @oyd_report.save
        end unless pluginInfo['reports'].nil?
        
        return @plugin.id
    end

    def create_tasks(plugin, tasks, config)
        # create tasks
        tasks.each do |task|
            OydTask.where(plugin_id: plugin.id, identifier: task['identifier']).destroy_all
            cmd = Base64.decode64(task['command'])
            if !config.nil? && JSON.parse(config.to_s.gsub('=>', ':')).count > 0
                config.each do |conf|
                    cmd = cmd.gsub('[' + conf[0].upcase + ']', conf[1].to_s)
                end
            end
            cmd = Base64.encode64(cmd).delete("\n").rstrip

            @oyd_task = OydTask.new(
                plugin_id: plugin.id,
                identifier: task['identifier'],
                command: cmd,
                schedule: task['schedule'],
                next_run: Time.now + 1.day)
            @oyd_task.save
        end unless tasks.nil?
    end

    def create_repos(plugin, repos, params)
        repos.each do |repo|
            repo_name = repo["name"]
            if params.count > 0
                params.each do |param|
                    repo_name = repo_name.gsub('[' + param[0].upcase + ']', param[1])
                end
            end

            repo_identifier = repo["identifier"]
            if params.count > 0
                params.each do |param|
                    repo_identifier = repo_identifier.gsub('[' + param[0].upcase + ']', param[1])
                end
            end

            repo_pubkey = ""
            if repo["encryption"]
                @settings_repo = Repo.where(
                    user_id: @plugin.owner_id,
                    identifier: 'oyd.settings')
                if @settings_repo.count > 0
                    repo_pubkey = @settings_repo.first.public_key
                end
            end
            @r = Repo.new(
                user_id: @plugin.owner_id,
                name: repo_name,
                identifier: repo_identifier,
                public_key: repo_pubkey)
            @r.save
        end
    end

    def parseConfigRepos(itemConfig)
        newItemConfig = itemConfig.dup
        repos = itemConfig['repos']
        fields = itemConfig['fields']
        repos.each do |key, repo|
            repo.each do |field, value|
                if value =~ /.*\[.*\].*/
                    # check if it is in itemConfig["fields"]
                    fields.each do |field_item|
                        field_item.each do |field_key, field_repo|
                            field_repo.each do |field_name, field_value|
                                if value =~ /.*\[#{field_name.to_s.upcase}\].*/
                                    value = value.gsub('[' + field_name.to_s.upcase + ']', field_value.to_s)
                                end
                            end
                        end
                    end
                    # also search default path
                    orig_value = value
                    value = value[1..-2]
                    group = value.split('_').first.downcase
                    new_value = value.split('_')[1..10].join('_')
                    if !itemConfig[group].nil?
                        value = readConfigValue(new_value, group, itemConfig)
                    else
                        if !itemConfig[group + 's'].nil?
                            value = readConfigValue(new_value, group + 's', itemConfig)
                        else
                            value = orig_value
                        end
                    end
                    newItemConfig['repos'][key][field] = value
                end
            end
        end
        return newItemConfig
    end

    def mergeConfigFields(itemConfig, input_str)
        input = JSON.parse(input_str)
        newItemConfig = itemConfig.dup
        fields = itemConfig['fields']
        fields_item_count = 0
        fields.each do |field_item|
            field_item.each do |key, repo|
                repo.each do |field, value|
                    if value =~ /^\[.*\]$/
                        value = value[1..-2].to_s.upcase
                        new_value = ""
                        input.each do |input_field, input_value|
                            if value.to_s == input_field.to_s.upcase
                                new_value = input_value
                                break
                            end
                        end
                        newItemConfig['fields'][fields_item_count][key][field] = new_value
                    end
                end
            end
            fields_item_count += 1
        end
        return newItemConfig
    end

    def parseConfigValue(value, config)
        if !config.nil? && JSON.parse(config.to_s.gsub('=>', ':')).count > 0
            config.each do |conf|
                value = value.gsub('[' + conf[0].upcase + ']', conf[1])
            end
        end
        return value

    end

    def parseConfig(input, config)
        output = input.dup
        input.each do |key, value|
            output[key] = parseConfigValue(value, config)
        end
        return output
    end

    def parseConfigArray(input_array, config)
        output_array = []
        input_array.each do |input|
            output_array << parseConfig(input, config)
        end
        return output_array
    end

    def readConfigValue(value, group, config)
        key = value.split('_').first.downcase
        item = value.split('_')[1..10].join('_').downcase
        retVal = config[group][key][item] rescue ""
        return retVal
    end

    def toParams(input, prefix)
        top = {}
        input.each do |key, values|
            values.each do |field, value|
                top[prefix.to_s.upcase + "_" + key.to_s.upcase + "_" + field.to_s.upcase] = value.to_s
            end
        end
        return top
    end

    def mergeParams(input1, input2_str)
        input2 = JSON.parse(input2_str.to_s) rescue {}
        return input1.merge(input2.stringify_keys.transform_keys(&:upcase))
    end
end
