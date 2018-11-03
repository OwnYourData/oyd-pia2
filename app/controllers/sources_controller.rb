class SourcesController < ApplicationController
    include ApplicationHelper
    include SessionsHelper

    before_action :logged_in_user

    def edit
        @source_id = params[:id]
        token = session[:token]
        source_url = getServerUrl() + "/api/sources/" + @source_id.to_s
        response = HTTParty.get(source_url,
            headers: { 'Content-Type' => 'application/json',
                       'Authorization' => 'Bearer ' + token } )
        if response.code != 200
            flash[:warning] = oyd_backend_translate(response.parsed_response['error'].to_s, params[:locale])
            redirect_to sources_path
            return
        end

        @oyd_source = response.parsed_response
        source_config = JSON.parse(@oyd_source["config"].to_s)["config"]
        source_repo_config = JSON.parse(@oyd_source["config"].to_s)["repos"] rescue nil
        source_fields_config = JSON.parse(@oyd_source["config_values"].to_s)["fields"].first.values.first rescue nil
        @configHtml = ''

        # if source is unconfigured then configuration fields only are shown - 
        # walk through fields
        if source_config['form'].to_s == ""
            @configHtml = '<p>' + t('sources.nothing_to_configure') + '</p>'
        else
            @configHtml = Base64.decode64(source_config['form'].to_s).dup.force_encoding(Encoding::UTF_8)
        end
        if @oyd_source["configured"]
            source_fields_config.each do |item|
                @configHtml = @configHtml.gsub('[' + item.first.to_s.upcase + ']', item.last.to_s)
            end unless source_fields_config.nil?

        #     # if source is confiuged then all fields are shown
        #     config_options = {}

        #     # walk through repos
        #     source_repo_config.each do |repo|
        #         config_options[repo.first.to_s] = {}
        #         repo.last.each do |key, value|
        #             config_options[repo.first.to_s][key] = value
        #         end
        #     end unless source_repo_config.nil? 
        #     # walk through fields
        #     # source_config["fields"].each do |field_item|
        #     #     field_item.each do |repo|
        #     #         if config_options[repo.first.to_s].nil?
        #     #             config_options[repo.first.to_s] = {}
        #     #         end
        #     #         repo.last.each do |key, value|
        #     #             config_options[repo.first.to_s][key] = ""
        #     #         end
        #     #     end
        #     # end
        #     # instead of walking through fields, add form code!

        #     # build UI with hashlist
        #     config_options.each do |config|
        #         @configHtml += '<p style="width: 100%; margin-top:35px; border-bottom: 2px solid lightgray;line-height: 0.1em;"><span style="background:#fff;padding-right: 7px;">' + t('data.repo_title') + ': ' + config.first.to_s.upcase + '</span></p>'
        #         config_options[config.first.to_s].each do |key, value|
        #             @configHtml += '<label for="' + config.first.to_s + '_' + key.to_s + '">' + key.to_s.titleize + '</label>'
        #             @configHtml += '<input class="form-control" type="text" name="' + config.first.to_s + '_' + key.to_s + '", value= "' + value.to_s + '">'
        #         end
        #     end
        else
            source_config["fields"].first.values.first.each do |item|
                @configHtml = @configHtml.gsub('[' + item.first.to_s.upcase + ']', "")
            end unless source_config["fields"].count == 0
        end
        @source_title = @oyd_source["name"]

    end

    def update
        token = session[:token]
        source_configure_url = getServerUrl() + "/api/sources/" + params[:source_id].to_s + "/configure"
        response = HTTParty.post(source_configure_url,
            headers: { 'Content-Type' => 'application/json',
                       'Authorization' => 'Bearer ' + token },
            body: { config: params.to_json }.to_json )
        if response.code == 200
            flash[:info] = t('data.success_update_message')
        else
            flash[:warning] = t('data.error_message') + ": " + 
                oyd_backend_translate(response.parsed_response['error'].to_s, params[:locale])
        end
        redirect_to sources_path
    end

    def destroy
        token = session[:token]
        destroy_source_url = getServerUrl() + "/api/sources/" + params[:source_id].to_s
        retVal = HTTParty.delete(destroy_source_url,
            headers: { 'Accept' => '*/*',
                       'Content-Type' => 'application/json',
                       'Authorization' => 'Bearer ' + token } )
        if retVal.code == 200
            flash[:info] = t('data.success_message')
        else
            flash[:warning] = t('data.error_message') + ": " + 
                oyd_backend_translate(retVal.parsed_response['error'].to_s, params[:locale])
        end
        redirect_to sources_path
    end
end
