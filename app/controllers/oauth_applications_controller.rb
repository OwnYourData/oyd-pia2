class OauthApplicationsController < ApplicationController
  include ApplicationHelper
  include PluginsHelper
  include SessionsHelper

  before_action :logged_in_user
  before_action :set_application, only: %i[show edit update destroy]

  def index
    @applications = current_user.oauth_applications.ordered_by(:created_at)
  end

  def show
  end

  def new
    @code_challenge = params[:code_challenge].to_s
    if @code_challenge == ""
      flash[:error] = "PKCE: Missing Code Challenge"
      redirect_to root_path
      return
    end
    @code_challenge_method = params[:code_challenge_method].to_s
    if @code_challenge_method == ""
      @code_challenge_method = "plain"
    end
    @user = User.find(current_user["id"])
    @plugin = @user.oauth_applications.where(identifier: params[:client_id].to_s)
    if @plugin.count == 0
      response = HTTParty.get("https://sam.data-vault.eu/api/plugins/").parsed_response rescue []
      lang = params["locale"] || "en"
      pluginInfo = {}
      response.each {|i| pluginInfo = i if (i["identifier"] == params[:client_id].to_s && i["language"] == lang)}
      if pluginInfo == {}
        flash[:error] = "Unknown Plugin '" + params[:client_id].to_s + "'"
        redirect_to root_path
        return
      else
        plugin_id = create_plugin_helper(pluginInfo, @user.id)
        @plugin = Doorkeeper::Application.find(plugin_id)
        @plugin.update_attributes(redirect_uri: params[:redirect_uri].to_s)
      end
    else
      @plugin = @plugin.first
      ru = params[:redirect_uri].to_s
      @ag = Doorkeeper::AccessGrant.new(
                resource_owner_id: @plugin.user.id, 
                application_id: @plugin.id, 
                token: SecureRandom.alphanumeric(32), 
                code_challenge: @code_challenge,
                code_challenge_method: @code_challenge_method,
                expires_in: Time.now+2.hours, 
                redirect_uri: ru.to_s)
      @ag.save
      if ru.include?("?")
        # redirect_to params[:redirect_uri].to_s + "&client_id=" + @plugin.uid + "&client_secret=" + @plugin.secret
        redirect_to params[:redirect_uri].to_s + "&client_id=" + @plugin.uid + "&code=" + @ag.token
      else
        # redirect_to params[:redirect_uri].to_s + "?client_id=" + @plugin.uid
        redirect_to params[:redirect_uri].to_s + "?client_id=" + @plugin.uid + "&code=" + @ag.token
      end
      return
    end
  end

  def create
    require 'securerandom'
    if params[:commit].to_s == "Authorize"
      @plugin = Doorkeeper::Application.find(params[:plugin_id])
      @ag = Doorkeeper::AccessGrant.new(
                resource_owner_id: @plugin.user.id, 
                application_id: @plugin.id, 
                token: SecureRandom.alphanumeric(32), 
                code_challenge: params[:code_challenge].to_s,
                code_challenge_method: params[:code_challenge_method].to_s,
                expires_in: Time.now+2.hours, 
                redirect_uri: @plugin.redirect_uri.to_s)
      @ag.save
      redirect_to @plugin.redirect_uri.to_s + "?client_id=" + @plugin.uid + "&code=" + @ag.token
    else
      redirect_to root_path
    end
  end

  def edit

  end

  def update
    if @application.update(application_params)
      flash[:notice] = I18n.t(:notice, scope: %i[doorkeeper flash applications update])
      redirect_to oauth_application_url(@application)
    else
      render :edit
    end
  end

  def destroy
    if @application.destroy
      flash[:notice] = I18n.t(:notice, scope: %i[doorkeeper flash applications destroy])
    end

    redirect_to oauth_applications_url
  end

  private

    def set_application
      @application = current_user.oauth_applications.find(params[:id])
    end

    def application_params
      params.require(:doorkeeper_application).permit(:name, :redirect_uri, :scopes, :confidential)
    end
end
