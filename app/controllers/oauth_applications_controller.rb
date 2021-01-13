class OauthApplicationsController < ApplicationController
  include ApplicationHelper
  include SessionsHelper

  before_action :logged_in_user
  before_action :set_application, only: %i[show edit update destroy]

  def index
    @applications = current_user.oauth_applications.ordered_by(:created_at)
  end

  def show
  end

  def new
    @user = User.find(current_user["id"])
    @plugin = @user.oauth_applications.where(identifier: params[:client_id].to_s)
    if @plugin.count == 0
      @plugin = @user.oauth_applications.new(name: params[:client_id].to_s, identifier: params[:client_id].to_s, redirect_uri: params[:redirect_uri].to_s).save
    else
      @plugin = @plugin.first
      @plugin.update_attributes(redirect_uri: params[:redirect_uri].to_s)
    end
  end

  def create
    if params["commit"].to_s == "Authorize"
      @plugin = Doorkeeper::Application.find(params[:plugin_id])
      @ag = Doorkeeper::AccessGrant.new(
                resource_owner_id: @plugin.user.id, 
                application_id: @plugin.id, 
                token: Doorkeeper::OAuth::Helpers::UniqueToken, 
                expires_in: Time.now+2.hours, 
                redirect_uri: params[:redirect_uri].to_s)
      @ag.save
      redirect_to params[:redirect_uri].to_s + "?client_id=" + @plugin.uid + "&client_secret=" + @plugin.secret + "&code=" + @ag.token
    else
      redirect_to root_path
    end
  end

  def edit; end

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
