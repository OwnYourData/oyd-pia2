module Api
    module V1
        class SemanticsController < ApiController
            include ApplicationHelper
            include SessionsHelper

            skip_before_action :doorkeeper_authorize!, only: [:active]

            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def schema
                if doorkeeper_token.nil?
                    render json: {"error": "invalid token"},
                           status: 403
                    return
                end
                @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                user_id = @app.owner_id
                user_repos = @app.user.repos.pluck(:id)
                @items = Item.where(repo_id: user_repos).where.not(schema_dri: nil).pluck(:repo_id, :schema_dri).uniq
                retVal = []
                @items.each do |item|
                    @repo = Repo.find(item.first)
                    repo_identifier = @repo.identifier
                    if check_permission(repo_identifier, @app, PermType::READ)
                        retVal << item.last
                    end
                end
                render json: retVal.uniq,
                       status: 200
            end

            def table
                if doorkeeper_token.nil?
                    render json: {"error": "invalid token"},
                           status: 403
                    return
                end
                @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                tables = @app.user.repos.pluck(:name).uniq.compact rescue []
                render json: tables,
                       status: 200
             end

            def info
                @app = Doorkeeper::Application.find(doorkeeper_token.application_id)
                user_name = @app.user.email.to_s rescue ""
                render json: {"name": user_name},
                       status: 200
            end

            def active
                render json: { 
                    "active": true,
                    "auth": true,
                    "repos": true,
                    "oauth": [{"type": "authorization_code"}] }, status: 200
            end
        end
    end
end