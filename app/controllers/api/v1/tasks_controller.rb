module Api
	module V1
		class TasksController < ApiController
			# respond only to JSON requests
			respond_to :json
			respond_to :html, only: []
			respond_to :xml, only: []

			def index
			end

			def active
				@tasks = OydTask.where("next_run < ? or next_run IS ?", 
									   Time.now, nil)
				render json: @tasks.to_json, status: 200
			end

			def create
				plugin_id = doorkeeper_token.application_id
				@task = OydTask.new(
					plugin_id: plugin_id,
					identifier: params[:identifier],
					command: params[:command],
					schedule: params[:schedule],
					next_run: nil)
				if @task.save
					render json: { "task_id": @task.id },
						   status: 200
				else
					render json: { "error": @task.errors.messages.to_s}
				end
			end

			def update
				plugin_id = doorkeeper_token.application_id
				identifier = params[:id]
				@task = OydTask.where(plugin_id: plugin_id,
								   identifier: identifier).first
				if @task.nil?
					render json: { "error": "Task not found" }, status: 404
				else
					@task.update_attributes(next_run: params[:next_run])
					render json: { "task_id": @task.id }, status: 200
				end
			end

			def delete
				@task = OydTask.find(params[:id])
				@task.destroy
				render json: { "task_id": params[:id] }, status: 200
			end

		end
	end
end
