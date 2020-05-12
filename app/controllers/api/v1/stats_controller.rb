module Api
	module V1
		class StatsController < ApiController
			skip_before_action :doorkeeper_authorize!

			# respond only to JSON requests
			respond_to :json
			respond_to :html, only: []
			respond_to :xml, only: []


			def index
				if params[:password].to_s == ENV["STATS_PASSWORD"].to_s && params[:password].to_s.length > 0
					if params[:week].to_s == ""
						render json: summary_stats.to_json,
							   status: 200
					else
						render json: weekly_stats(params[:week].to_s).to_json,
							   status: 200
					end
				else
					render json: [],
						   status: 200
				end
			end

			private 

			def summary_stats
				{
					"all_users": User.count,
					"activated_users": User.where.not(recovery_password_key: nil).count,
					"active_users": Repo.where(id: Item.where.not(repo_id: Repo.where(identifier: "oyd.settings").pluck(:id)).pluck(:repo_id).uniq).pluck(:user_id).uniq.count,
					"items": Item.count,

				}
			end

			def weekly_stats(week)
				new_users = 0
				new_items = 0
				active_repos = 0
				active_users = 0
				begin
					begin_ts = DateTime.strptime(week, "%U-%Y").beginning_of_week
					end_ts = DateTime.strptime(week, "%U-%Y").end_of_week

					new_users = User.where("created_at >= ? AND created_at <= ?", begin_ts, end_ts).count
					@items = Item.where("created_at >= ? AND created_at <= ?", begin_ts, end_ts)
					new_items = @items.count
					active_repos = @items.pluck(:repo_id).uniq.count
					active_users = Repo.where(id: @items.pluck(:repo_id).uniq).pluck(:user_id).uniq.count

				rescue => ex
					puts "Error: " + ex.inspect.to_s
					new_users = -1
					new_items = -1
					active_repos = -1
					active_users = -1
				end

				{
					"new_users": new_users,
					"new_items": new_items,
					"active_repos": active_repos,
					"active_users": active_users
				}
			end
		end
	end
end

