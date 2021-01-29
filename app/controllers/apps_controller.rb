class AppsController < ApplicationController
    include ApplicationHelper
    include SessionsHelper

	before_action :logged_in_user

	def new
	end

	def plugin_config
		@plugin_id = params[:id]
		@plugin = Doorkeeper::Application.find(@plugin_id)
		plugin_config = JSON.parse(@plugin.config)
		@configHtml = ""
		if !plugin_config['form'].nil?
			@configHtml = Base64.decode64(plugin_config['form'].to_s)
		end
		@repoInfo = ""
		if !plugin_config['repos'].nil?
			@repoInfo = Base64.encode64(plugin_config['repos'].to_s).delete("\n")
		end
		@plugin_title = @plugin.name
	end

	def configure
		token = session[:token]
		plugin_configure_url = getServerUrl() + "/api/plugins/" + params[:plugin_id].to_s + "/configure"
		response = HTTParty.post(plugin_configure_url,
			headers: { 'Content-Type' => 'application/json',
					   'Authorization' => 'Bearer ' + token },
			body: { config: params.to_json, repos: params[:repos].to_s }.to_json )
		redirect_to plugins_path
	end

	def manifest
		require "base64"
		require "uri"
		create_app_url = getServerUrl() + "/api/plugins/create"
		token = session[:token]
		
		if params[:sam].to_s != "" && params[:sam].to_s != "0"
			manifest = "https://sam.data-vault.eu/api/plugins/" + params[:sam]
				response = HTTParty.post(create_app_url,
		            headers: { 'Content-Type' => 'application/json',
		                	   'Authorization' => 'Bearer ' + token },
		            body: { source_url: manifest,
		            	    config: {} }.to_json )
		else
			manifest = params[:manifest].to_s
			uri = URI.parse(manifest.strip.gsub(/\s+/, " ")) rescue ""
			if uri.kind_of?(URI::HTTP) or uri.kind_of?(URI::HTTPS)
				response = HTTParty.post(create_app_url,
		            headers: { 'Content-Type' => 'application/json',
		                	   'Authorization' => 'Bearer ' + token },
		            body: { source_url: manifest.strip.gsub(/\s+/, " "),
		            	    config: {} }.to_json )
			else
				if !base64?(manifest)
					manifest = Base64.encode64(manifest)
				end
		        response = HTTParty.post(create_app_url,
		            headers: { 'Content-Type' => 'application/json',
		                	   'Authorization' => 'Bearer ' + token },
		            body: { manifest: manifest,
		            	    config: {} }.to_json )
		    end
		end
		if response.code.to_s == "200"
			flash[:success] = "Plugin installed"
		else
			flash[:warning] = "Error"
		end
		redirect_to plugins_path
	end

	def manifest_update
		token = session[:token]
		manifest_update_url = getServerUrl() + "/api/plugins/" + params[:id] + "/manifest"
		response = HTTParty.put(manifest_update_url,
            headers: { 'Content-Type' => 'application/json',
                	   'Authorization' => 'Bearer ' + token } )
		code = response.code rescue nil
		paresp = response.parsed_response rescue nil
		if code.to_s == "200"
			flash[:success] = t('plugins.plugin_update_success')
		else
			flash[:warning] = oyd_backend_translate(paresp['error'].to_s, params[:locale])
		end
		redirect_to plugins_path	
	end

	def update
		view_id = params[:details_view_id]
		update_view_url = getServerUrl() + "/api/views/" + view_id.to_s
		token = session[:token]
		response = HTTParty.put(update_view_url,
            headers: { 'Content-Type' => 'application/json',
                	   'Authorization' => 'Bearer ' + token },
            body: { name: params[:details_view_name],
            	    view_url: params[:details_view_url] }.to_json )

		# get plugin_id
		show_view_url = getServerUrl() + "/api/views/" + view_id.to_s
        view = HTTParty.get(show_view_url,
            headers: { 'Accept' => '*/*',
                       'Content-Type' => 'application/json',
                       'Authorization' => 'Bearer ' + token }).parsed_response
        plugin_id = view['plugin_id']

		# iterate over all permission params
		params.each do |param|
			if param.starts_with?("perm_")
				case param.slice(0,10)
				when "perm_READ_"
					if params[param.to_s] == 'true'
						if params["perm_IDENTIFIER_" + param.split("_")[2].to_s + "_delete"] == 'false'
							repo_identifier = params["perm_IDENTIFIER_" + param.split("_")[2].to_s].to_s
							allow = false
							if params[param.to_s].to_s == "true"
								allow = true
							end
							perm_url = getServerUrl() + "/api/apps/" + plugin_id.to_s + "/perms"
							response = HTTParty.post(perm_url,
								headers: { 'Content-Type' => 'application/json',
										   'Authorization' => 'Bearer ' + token },
								body: { plugin_id: plugin_id,
									    repo_identifier: repo_identifier,
									    perm_type: PermType::READ,
									    perm_allow: allow }.to_json )
						end
					end
				when "perm_WRITE"
					if params[param.to_s] == 'true'
						if params["perm_IDENTIFIER_" + param.split("_")[2].to_s + "_delete"] == 'false'
							repo_identifier = params["perm_IDENTIFIER_" + param.split("_")[2].to_s].to_s
							allow = false
							if params[param.to_s].to_s == "true"
								allow = true
							end
							perm_url = getServerUrl() + "/api/apps/" + plugin_id.to_s + "/perms"
							response = HTTParty.post(perm_url,
								headers: { 'Content-Type' => 'application/json',
										   'Authorization' => 'Bearer ' + token },
								body: { plugin_id: plugin_id,
									    repo_identifier: repo_identifier,
									    perm_type: PermType::WRITE,
									    perm_allow: allow }.to_json )
						end
					end
				when "perm_UPDAT"
					if params[param.to_s] == 'true'
						if params["perm_IDENTIFIER_" + param.split("_")[2].to_s + "_delete"] == 'false'
							repo_identifier = params["perm_IDENTIFIER_" + param.split("_")[2].to_s].to_s
							allow = false
							if params[param.to_s].to_s == "true"
								allow = true
							end
							perm_url = getServerUrl() + "/api/apps/" + plugin_id.to_s + "/perms"
							response = HTTParty.post(perm_url,
								headers: { 'Content-Type' => 'application/json',
										   'Authorization' => 'Bearer ' + token },
								body: { plugin_id: plugin_id,
									    repo_identifier: repo_identifier,
									    perm_type: PermType::UPDATE,
									    perm_allow: allow }.to_json )
						end
					end
				when "perm_DELET"
					if params[param.to_s] == 'true'
						if params["perm_IDENTIFIER_" + param.split("_")[2].to_s + "_delete"] == 'false'
							repo_identifier = params["perm_IDENTIFIER_" + param.split("_")[2].to_s].to_s
							allow = false
							if params[param.to_s].to_s == "true"
								allow = true
							end
							perm_url = getServerUrl() + "/api/apps/" + plugin_id.to_s + "/perms"
							response = HTTParty.post(perm_url,
								headers: { 'Content-Type' => 'application/json',
										   'Authorization' => 'Bearer ' + token },
								body: { plugin_id: plugin_id,
									    repo_identifier: repo_identifier,
									    perm_type: PermType::DELETE,
									    perm_allow: allow }.to_json )
						end
					end
				when "perm_IDENT"
					if param.split(//).last(7).join == '_delete'
						if params[param] == 'true'
							repo_identifier = params["perm_IDENTIFIER_" + param.split("_")[2].to_s].to_s
							perm_url = getServerUrl() + "/api/apps/" + plugin_id.to_s + "/perms_destroy"
							response = HTTParty.post(perm_url,
								headers: { 'Content-Type' => 'application/json',
										   'Authorization' => 'Bearer ' + token },
								body: { repo_identifier: repo_identifier }.to_json )
						end
					end
				else
					permId = param.split("_")[1].to_s
					allow = false
					if params[param.to_s].to_s == "true"
						allow = true
					end
					perm_url = getServerUrl() + "/api/apps/" + plugin_id.to_s + "/perms/" + permId
					response = HTTParty.put(perm_url,
						headers: { 'Content-Type' => 'application/json',
								   'Authorization' => 'Bearer ' + token },
						body: { perm_allow: allow }.to_json )

				end
			end
		end

		redirect_to user_path
	end

	def plugin_update
		plugin_id = params[:details_plugin_id]
		update_plugin_url = getServerUrl() + "/api/plugins/" + plugin_id.to_s
		token = session[:token]
		response = HTTParty.put(update_plugin_url,
            headers: { 'Content-Type' => 'application/json',
                	   'Authorization' => 'Bearer ' + token },
            body: { name: params[:details_plugin_name] }.to_json )

		# iterate over all permission params
		params.keys.each do |param|
			if param.starts_with?("perm_")
				case param.to_s.slice(0,10)
				when "perm_READ_"
					if params[param.to_s] == 'true'
						if params["perm_IDENTIFIER_" + param.split("_")[2].to_s + "_delete"] == 'false'
							repo_identifier = params["perm_IDENTIFIER_" + param.split("_")[2].to_s].to_s
							allow = false
							if params[param.to_s].to_s == "true"
								allow = true
							end
							perm_url = getServerUrl() + "/api/apps/" + plugin_id.to_s + "/perms"
							response = HTTParty.post(perm_url,
								headers: { 'Content-Type' => 'application/json',
										   'Authorization' => 'Bearer ' + token },
								body: { plugin_id: plugin_id,
									    repo_identifier: repo_identifier,
									    perm_type: PermType::READ,
									    perm_allow: allow }.to_json )
						end
					end
				when "perm_WRITE"
					if params[param.to_s] == 'true'
						if params["perm_IDENTIFIER_" + param.split("_")[2].to_s + "_delete"] == 'false'
							repo_identifier = params["perm_IDENTIFIER_" + param.split("_")[2].to_s].to_s
							allow = false
							if params[param.to_s].to_s == "true"
								allow = true
							end
							perm_url = getServerUrl() + "/api/apps/" + plugin_id.to_s + "/perms"
							response = HTTParty.post(perm_url,
								headers: { 'Content-Type' => 'application/json',
										   'Authorization' => 'Bearer ' + token },
								body: { plugin_id: plugin_id,
									    repo_identifier: repo_identifier,
									    perm_type: PermType::WRITE,
									    perm_allow: allow }.to_json )
						end
					end
				when "perm_UPDAT"
					if params[param.to_s] == 'true'
						if params["perm_IDENTIFIER_" + param.split("_")[2].to_s + "_delete"] == 'false'
							repo_identifier = params["perm_IDENTIFIER_" + param.split("_")[2].to_s].to_s
							allow = false
							if params[param.to_s].to_s == "true"
								allow = true
							end
							perm_url = getServerUrl() + "/api/apps/" + plugin_id.to_s + "/perms"
							response = HTTParty.post(perm_url,
								headers: { 'Content-Type' => 'application/json',
										   'Authorization' => 'Bearer ' + token },
								body: { plugin_id: plugin_id,
									    repo_identifier: repo_identifier,
									    perm_type: PermType::UPDATE,
									    perm_allow: allow }.to_json )
						end
					end
				when "perm_DELET"
					if params[param.to_s] == 'true'
						if params["perm_IDENTIFIER_" + param.split("_")[2].to_s + "_delete"] == 'false'
							repo_identifier = params["perm_IDENTIFIER_" + param.split("_")[2].to_s].to_s
							allow = false
							if params[param.to_s].to_s == "true"
								allow = true
							end
							perm_url = getServerUrl() + "/api/apps/" + plugin_id.to_s + "/perms"
							response = HTTParty.post(perm_url,
								headers: { 'Content-Type' => 'application/json',
										   'Authorization' => 'Bearer ' + token },
								body: { plugin_id: plugin_id,
									    repo_identifier: repo_identifier,
									    perm_type: PermType::DELETE,
									    perm_allow: allow }.to_json )
						end
					end
				when "perm_IDENT"
					if param.split(//).last(7).join == '_delete'
						if params[param] == 'true'
							repo_identifier = params["perm_IDENTIFIER_" + param.split("_")[2].to_s].to_s
							perm_url = getServerUrl() + "/api/apps/" + plugin_id.to_s + "/perms_destroy"
							response = HTTParty.post(perm_url,
								headers: { 'Content-Type' => 'application/json',
										   'Authorization' => 'Bearer ' + token },
								body: { repo_identifier: repo_identifier }.to_json )
						end
					end
				else
					permId = param.split("_")[1].to_s
					allow = false
					if params[param.to_s].to_s == "true"
						allow = true
					end
					perm_url = getServerUrl() + "/api/apps/" + plugin_id.to_s + "/perms/" + permId
					response = HTTParty.put(perm_url,
						headers: { 'Content-Type' => 'application/json',
								   'Authorization' => 'Bearer ' + token },
						body: { perm_allow: allow }.to_json )

				end
			end
		end

		redirect_to plugins_path
	end

	def destroy
		destroy_app_url = getServerUrl() + "/api/apps/destroy"
		token = session[:token]
        response = HTTParty.post(destroy_app_url,
            headers: { 'Content-Type' => 'application/json',
                	   'Authorization' => 'Bearer ' + token },
            body: { oyd_view_id: params[:oyd_view_id] }.to_json )
		redirect_to user_path
	end

	def plugin_destroy
		token = session[:token]
		destroy_plugin_url = getServerUrl() + "/api/plugins/" + params[:plugin_id]
        retVal = HTTParty.delete(destroy_plugin_url,
            headers: { 'Accept' => '*/*',
                       'Content-Type' => 'application/json',
                	   'Authorization' => 'Bearer ' + token } )
		if retVal.code == 200
	        flash[:info] = t('data.success_message')
	    else
	    	flash[:warning] = t('data.error_message') + ": " + 
	        oyd_backend_translate(retVal.parsed_response['error'].to_s, params[:locale])
	    end
		redirect_to plugins_path
	end

	def detail
        view_info_url = getServerUrl() + "/api/views/" + params[:oyd_view_id].to_s
        token = session[:token]
        @app_info = HTTParty.get(view_info_url,
            headers: { 'Accept' => '*/*',
                       'Content-Type' => 'application/json',
                       'Authorization' => 'Bearer ' + token }).parsed_response

        perm_info_url = getServerUrl() + "/api/apps/" + 
        	@app_info['plugin_id'].to_s + "/perms"
        @perm_info = HTTParty.get(perm_info_url,
            headers: { 'Accept' => '*/*',
                       'Content-Type' => 'application/json',
                       'Authorization' => 'Bearer ' + token }).parsed_response
        @repos = @perm_info.map{ |x| x["repo_identifier"] }.uniq
        @perm_html = '<tr id="placeholder"></tr>'
        i = 0
        @repos.each do |repo|
	        @perm_html += '<tr>'
			@perm_html += '<td><span class="permName">' + repo.to_s + '</span>'
			@perm_html += '<span class="deletePerm" onclick="$(this).closest(\\\'tr\\\').hide();$(\\\'#perm_IDENTIFIER_' + i.to_s + '_delete\\\').val(\\\'true\\\');"><i class="fa fa-trash" aria-hidden="true"></i></span>'
			@perm_html += '<input type="hidden" id="perm_IDENTIFIER_' + i.to_s + '" name="perm_IDENTIFIER_' + i.to_s + '" value="' + repo.to_s  + '">'
			@perm_html += '<input type="hidden" id="perm_IDENTIFIER_' + i.to_s + '_delete" name="perm_IDENTIFIER_' + i.to_s + '_delete" value="false">'
			@perm_html += '</td>'

			# READ permission
			fieldHtml = ''
			tdId = ''
			allow = false
			@perm_info.each do |sub|
				if  sub["repo_identifier"] == repo &&
						sub["perm_type"] == PermType::READ
					tdId = 'perm_' + sub["id"].to_s
					if sub["perm_allow"]
						allow = true
						fieldHtml = '<input type="hidden" id="perm_' + sub["id"].to_s + '_value" name="perm_' + sub["id"].to_s + '_value" value="true">'
					else 
						fieldHtml = '<input type="hidden" id="perm_' + sub["id"].to_s + '_value" name="perm_' + sub["id"].to_s + '_value" value="false">'
					end
				end
			end
			if fieldHtml == ''
				fieldHtml = '<input type="hidden" id="perm_READ_' + i.to_s + '_value" name="perm_READ_' + i.to_s + '_value" value="false">'
				tdId = 'perm_READ_' + i.to_s
			end
			@perm_html += '  <td class="text-center permission" id="' + tdId.to_s + '">'
			@perm_html += fieldHtml
			if allow
				@perm_html += '    <i class="fa fa-check-square-o" aria-hidden="true"></i></td>'
			else
				@perm_html += '    <i class="fa fa-square-o" aria-hidden="true"></i></td>'
			end

			# WRITE permission
			fieldHtml = ''
			allow = false
			@perm_info.each do |sub|
				if  sub["repo_identifier"] == repo &&
						sub["perm_type"] == PermType::WRITE
					tdId = 'perm_' + sub["id"].to_s
					if sub["perm_allow"]
						allow = true
						fieldHtml = '<input type="hidden" id="perm_' + sub["id"].to_s + '_value" name="perm_' + sub["id"].to_s + '_value" value="true">'
					else 
						fieldHtml = '<input type="hidden" id="perm_' + sub["id"].to_s + '_value" name="perm_' + sub["id"].to_s + '_value" value="false">'
					end
				end
			end
			if fieldHtml == ''
				fieldHtml = '<input type="hidden" id="perm_WRITE_' + i.to_s + '_value" name="perm_WRITE_' + i.to_s + '_value" value="false">'
				tdId = 'perm_WRITE_' + i.to_s
			end
			@perm_html += '  <td class="text-center permission" id="' + tdId.to_s + '">'
			@perm_html += fieldHtml
			if allow
				@perm_html += '    <i class="fa fa-check-square-o" aria-hidden="true"></i></td>'
			else
				@perm_html += '    <i class="fa fa-square-o" aria-hidden="true"></i></td>'
			end

			# UPDATE permission
			fieldHtml = ''
			allow = false
			@perm_info.each do |sub|
				if  sub["repo_identifier"] == repo &&
						sub["perm_type"] == PermType::UPDATE
					tdId = 'perm_' + sub["id"].to_s
					if sub["perm_allow"]
						allow = true
						fieldHtml = '<input type="hidden" id="perm_' + sub["id"].to_s + '_value" name="perm_' + sub["id"].to_s + '_value" value="true">'
					else 
						fieldHtml = '<input type="hidden" id="perm_' + sub["id"].to_s + '_value" name="perm_' + sub["id"].to_s + '_value" value="false">'
					end
				end
			end
			if fieldHtml == ''
				fieldHtml = '<input type="hidden" id="perm_UPDATE_' + i.to_s + '_value" name="perm_UPDATE_' + i.to_s + '_value" value="false">'
				tdId = 'perm_UPDATE_' + i.to_s
			end
			@perm_html += '  <td class="text-center permission" id="' + tdId.to_s + '">'
			@perm_html += fieldHtml
			if allow
				@perm_html += '    <i class="fa fa-check-square-o" aria-hidden="true"></i></td>'
			else
				@perm_html += '    <i class="fa fa-square-o" aria-hidden="true"></i></td>'
			end

			# DELETE permission
			fieldHtml = ''
			allow = false
			@perm_info.each do |sub|
				if  sub["repo_identifier"] == repo &&
						sub["perm_type"] == PermType::DELETE
					tdId = 'perm_' + sub["id"].to_s
					if sub["perm_allow"]
						allow = true
						fieldHtml = '<input type="hidden" id="perm_' + sub["id"].to_s + '_value" name="perm_' + sub["id"].to_s + '_value" value="true">'
					else 
						fieldHtml = '<input type="hidden" id="perm_' + sub["id"].to_s + '_value" name="perm_' + sub["id"].to_s + '_value" value="false">'
					end
				end
			end
			if fieldHtml == ''
				fieldHtml = '<input type="hidden" id="perm_DELETE_' + i.to_s + '_value" name="perm_DELETE_' + i.to_s + '_value" value="false">'
				tdId = 'perm_DELETE_' + i.to_s
			end
			@perm_html += '  <td class="text-center permission" id="' + tdId.to_s + '">'
			@perm_html += fieldHtml
			if allow
				@perm_html += '    <i class="fa fa-check-square-o" aria-hidden="true"></i></td>'
			else
				@perm_html += '    <i class="fa fa-square-o" aria-hidden="true"></i></td>'
			end
			@perm_html += '</tr>'
			i = i+1
		end
		respond_to do |format|
			format.js
		end
	end

	def plugin_detail
        token = session[:token]
        plugin_info_url = getServerUrl() + "/api/plugins/" + params[:plugin_id].to_s
        @plugin_info = HTTParty.get(plugin_info_url,
            headers: { 'Accept' => '*/*',
                       'Content-Type' => 'application/json',
                       'Authorization' => 'Bearer ' + token }).parsed_response.first
        perm_info_url = getServerUrl() + "/api/apps/" + 
        	params[:plugin_id].to_s + "/perms"
        @perm_info = HTTParty.get(perm_info_url,
            headers: { 'Accept' => '*/*',
                       'Content-Type' => 'application/json',
                       'Authorization' => 'Bearer ' + token }).parsed_response
        @repos = @perm_info.map{ |x| x["repo_identifier"] }.uniq
        @perm_html = '<tr id="placeholder"></tr>'
        i = 0
        @repos.each do |repo|
	        @perm_html += '<tr>'
			@perm_html += '<td><span class="permName">' + repo.to_s + '</span>'
			@perm_html += '<span class="deletePerm" onclick="$(this).closest(\\\'tr\\\').hide();$(\\\'#perm_IDENTIFIER_' + i.to_s + '_delete\\\').val(\\\'true\\\');"><i class="fa fa-trash" aria-hidden="true"></i></span>'
			@perm_html += '<input type="hidden" id="perm_IDENTIFIER_' + i.to_s + '" name="perm_IDENTIFIER_' + i.to_s + '" value="' + repo.to_s  + '">'
			@perm_html += '<input type="hidden" id="perm_IDENTIFIER_' + i.to_s + '_delete" name="perm_IDENTIFIER_' + i.to_s + '_delete" value="false">'
			@perm_html += '</td>'

			# READ permission
			fieldHtml = ''
			tdId = ''
			allow = false
			@perm_info.each do |sub|
				if  sub["repo_identifier"] == repo &&
						sub["perm_type"] == PermType::READ
					tdId = 'perm_' + sub["id"].to_s
					if sub["perm_allow"]
						allow = true
						fieldHtml = '<input type="hidden" id="perm_' + sub["id"].to_s + '_value" name="perm_' + sub["id"].to_s + '_value" value="true">'
					else 
						fieldHtml = '<input type="hidden" id="perm_' + sub["id"].to_s + '_value" name="perm_' + sub["id"].to_s + '_value" value="false">'
					end
				end
			end
			if fieldHtml == ''
				fieldHtml = '<input type="hidden" id="perm_READ_' + i.to_s + '_value" name="perm_READ_' + i.to_s + '_value" value="false">'
				tdId = 'perm_READ_' + i.to_s
			end
			@perm_html += '  <td class="text-center permission" id="' + tdId.to_s + '">'
			@perm_html += fieldHtml
			if allow
				@perm_html += '    <i class="fa fa-check-square-o" aria-hidden="true"></i></td>'
			else
				@perm_html += '    <i class="fa fa-square-o" aria-hidden="true"></i></td>'
			end

			# WRITE permission
			fieldHtml = ''
			allow = false
			@perm_info.each do |sub|
				if  sub["repo_identifier"] == repo &&
						sub["perm_type"] == PermType::WRITE
					tdId = 'perm_' + sub["id"].to_s
					if sub["perm_allow"]
						allow = true
						fieldHtml = '<input type="hidden" id="perm_' + sub["id"].to_s + '_value" name="perm_' + sub["id"].to_s + '_value" value="true">'
					else 
						fieldHtml = '<input type="hidden" id="perm_' + sub["id"].to_s + '_value" name="perm_' + sub["id"].to_s + '_value" value="false">'
					end
				end
			end
			if fieldHtml == ''
				fieldHtml = '<input type="hidden" id="perm_WRITE_' + i.to_s + '_value" name="perm_WRITE_' + i.to_s + '_value" value="false">'
				tdId = 'perm_WRITE_' + i.to_s
			end
			@perm_html += '  <td class="text-center permission" id="' + tdId.to_s + '">'
			@perm_html += fieldHtml
			if allow
				@perm_html += '    <i class="fa fa-check-square-o" aria-hidden="true"></i></td>'
			else
				@perm_html += '    <i class="fa fa-square-o" aria-hidden="true"></i></td>'
			end

			# UPDATE permission
			fieldHtml = ''
			allow = false
			@perm_info.each do |sub|
				if  sub["repo_identifier"] == repo &&
						sub["perm_type"] == PermType::UPDATE
					tdId = 'perm_' + sub["id"].to_s
					if sub["perm_allow"]
						allow = true
						fieldHtml = '<input type="hidden" id="perm_' + sub["id"].to_s + '_value" name="perm_' + sub["id"].to_s + '_value" value="true">'
					else 
						fieldHtml = '<input type="hidden" id="perm_' + sub["id"].to_s + '_value" name="perm_' + sub["id"].to_s + '_value" value="false">'
					end
				end
			end
			if fieldHtml == ''
				fieldHtml = '<input type="hidden" id="perm_UPDATE_' + i.to_s + '_value" name="perm_UPDATE_' + i.to_s + '_value" value="false">'
				tdId = 'perm_UPDATE_' + i.to_s
			end
			@perm_html += '  <td class="text-center permission" id="' + tdId.to_s + '">'
			@perm_html += fieldHtml
			if allow
				@perm_html += '    <i class="fa fa-check-square-o" aria-hidden="true"></i></td>'
			else
				@perm_html += '    <i class="fa fa-square-o" aria-hidden="true"></i></td>'
			end

			# DELETE permission
			fieldHtml = ''
			allow = false
			@perm_info.each do |sub|
				if  sub["repo_identifier"] == repo &&
						sub["perm_type"] == PermType::DELETE
					tdId = 'perm_' + sub["id"].to_s
					if sub["perm_allow"]
						allow = true
						fieldHtml = '<input type="hidden" id="perm_' + sub["id"].to_s + '_value" name="perm_' + sub["id"].to_s + '_value" value="true">'
					else 
						fieldHtml = '<input type="hidden" id="perm_' + sub["id"].to_s + '_value" name="perm_' + sub["id"].to_s + '_value" value="false">'
					end
				end
			end
			if fieldHtml == ''
				fieldHtml = '<input type="hidden" id="perm_DELETE_' + i.to_s + '_value" name="perm_DELETE_' + i.to_s + '_value" value="false">'
				tdId = 'perm_DELETE_' + i.to_s
			end
			@perm_html += '  <td class="text-center permission" id="' + tdId.to_s + '">'
			@perm_html += fieldHtml
			if allow
				@perm_html += '    <i class="fa fa-check-square-o" aria-hidden="true"></i></td>'
			else
				@perm_html += '    <i class="fa fa-square-o" aria-hidden="true"></i></td>'
			end
			@perm_html += '</tr>'
			i = i+1
		end
		respond_to do |format|
			format.js
		end
	end

	def detail_password
        app_info_url = getServerUrl() + "/api/apps/" + params[:plugin_id].to_s
        token = session[:token]
        @app_info = HTTParty.get(app_info_url,
            headers: { 'Accept' => '*/*',
                       'Content-Type' => 'application/json',
                       'Authorization' => 'Bearer ' + token }).parsed_response.first
		respond_to do |format|
			format.js
		end
	end


	def connection_key
		@plugin = Doorkeeper::Application.find(params[:id])
		if !@plugin.nil?
			@plugin.oyd_installs.destroy_all
			@plugin.oyd_installs.new(code: '%06d' % rand(10 ** 6)).save
		end
		redirect_to plugins_path
	end
end