module Api
	module V1
		class NewsController < ApiController
			# respond only to JSON requests
			respond_to :json
			respond_to :html, only: []
			respond_to :xml, only: []

			def current
				@current_news = WeeklyNews.where(week: Time.now.strftime("%U-%Y")).pluck(:news_text)
				render json: @current_news, status: 200

			end
		end
	end
end
