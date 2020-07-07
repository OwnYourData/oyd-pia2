class LogsController < ApplicationController
    include ApplicationHelper
    include SessionsHelper

    before_action :logged_in_user

    def index
        begin
            @filterrific = initialize_filterrific(
                OydAccess.where(user_id: current_user["id"]),
                params[:filterrific],
                select_options: {
                    sorted_by: OydAccess.options_for_sorted_by,
                    with_plugin_id: Doorkeeper::Application.where(owner_id: current_user["id"]).order("LOWER(name)").map { |e| [e.name, e.id] }
                },
                persistence_id: "shared_key",
                default_filter_params: {},
                available_filters: [:sorted_by, :with_plugin_id, :with_created_at_gte],
                sanitize_params: true
            ) || return

            @logs = @filterrific.find.page(params[:page])
            respond_to do |format|
              format.html
              format.js 
            end

        rescue ActiveRecord::RecordNotFound => e
            # There is an issue with the persisted param_set. Reset it.
            puts "Had to reset filterrific params: #{e.message}"
            redirect_to(reset_filterrific_url(format: :html)) && return
        end
    end
end