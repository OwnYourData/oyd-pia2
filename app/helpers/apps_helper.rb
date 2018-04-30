module AppsHelper
	def create_apps(params, user_id)
		require 'httparty'
		require 'base64'

		if(params[:manifest].nil?)
			# download plugin infos from SAM (source_url)
			response = HTTParty.get(params[:source_url])
			pluginInfo = response.parsed_response rescue nil
		else
			pluginInfo = JSON.parse(Base64.decode64(params[:manifest])) rescue nil
		end

		if pluginInfo.nil?
			nil
			return
		end

		# create entry in OauthApplication
		@plugin = Doorkeeper::Application.where(
			owner_id: user_id,
			identifier: pluginInfo['identifier'])
		if @plugin.nil? || @plugin.count == 0
			@plugin = Doorkeeper::Application.new(
				owner_id: user_id,
				owner_type: 'User',
				name: pluginInfo['name'],
				identifier: pluginInfo['identifier'], 
				tasks: pluginInfo['tasks'].to_s.gsub('=>', ':'),
				config: pluginInfo['config'].to_s.gsub('=>', ':'),
				redirect_uri: "https://localhost:3000/oauth/callback" )
			retVal = @plugin.save
		else
			@plugin = @plugin.first
		end

		# create views
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

		# create report snippets
		@plugin.oyd_reports.destroy_all
		pluginInfo['reports'].each do |report|
			# data_prep = Base64.decode64(report['prep'])
			# report_view = Base64.decode64(report['view'])
			# answer_view
			# if !params[:config].nil? && JSON.parse(params[:config].to_s).count > 0
			# 	params[:config].each do |conf|
			# 		prep = prep.gsub('[' + conf[0].upcase + ']', conf[1])
			# 		view = view.gsub('[' + conf[0].upcase + ']', conf[1])
			# 	end
			# end
			# prep = Base64.encode64(prep).rstrip
			# view = Base64.encode64(view).rstrip

			@oyd_report = OydReport.new(
				plugin_id: @plugin.id,
				name: report['name'],
				identifier: report['identifier'],
				info_url: report['info_url'],
				data_prep: report['data_prep'],
				data_snippet: report['data_snippet'],
				report_view: report['report_view'],
				answer_view: report['answer_view'],
				answer_logic: report['answer_logic'])
			@oyd_report.save
		end unless pluginInfo['reports'].nil?

		# create entries in Permission
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
		
		@plugin.id
	end

	def create_tasks(plugin, tasks, config)
		# create tasks
		plugin.oyd_tasks.destroy_all
		tasks.each do |task|
			cmd = Base64.decode64(task['command'])
			if !config.nil? && JSON.parse(config.to_s.gsub('=>', ':')).count > 0
				config.each do |conf|
					cmd = cmd.gsub('[' + conf[0].upcase + ']', conf[1])
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

end
