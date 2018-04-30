class ApplicationController < ActionController::Base
	protect_from_forgery with: :exception, unless: -> { request.format.json? }
	before_action :set_locale, :cors_preflight_check
	after_action :cors_set_access_control_headers
	
	include SessionsHelper

	def missing
		flash[:warning] = "The following page does not exist: " + request.original_url
		redirect_to root_url
	end

	def default_url_options(options={})
		I18n.locale == :en ? {} : { locale: I18n.locale }
	end

	def cors_preflight_check
		if request.method == 'OPTIONS'
			headers['Access-Control-Allow-Origin'] = '*'
			headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
			headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-Prototype-Version, Token'
			headers['Access-Control-Max-Age'] = '1728000'

			render text: '', content_type: 'text/plain'
		end
	end

	def cors_set_access_control_headers
		headers['Access-Control-Allow-Origin'] = '*'
		headers['Access-Control-Allow-Methods'] = 'POST, GET, PUT, DELETE, OPTIONS'
		headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization, Token'
		headers['Access-Control-Max-Age'] = "1728000"
	end

	def doorkeeper_unauthorized_render_options(error: nil)
		{ json: { error: "Not authorized" } }
	end


	private

	def extract_locale_from_accept_language_header
		hal = request.env['HTTP_ACCEPT_LANGUAGE']
		if hal
			retval = hal.scan(/^[a-z]{2}/).first
			if "-en-de-".split(retval).count == 2
				retval
			else
				I18n.default_locale
			end
		else
			I18n.default_locale
		end
	end

	def set_locale
		I18n.locale = params[:locale] || extract_locale_from_accept_language_header
		Rails.application.routes.default_url_options[:locale]= I18n.locale
	end

	def current_resource_owner
		if doorkeeper_token
			if doorkeeper_token.resource_owner_id.nil?
				nil
			else
				if User.where(id: doorkeeper_token.resource_owner_id).count > 0
					User.find(doorkeeper_token.resource_owner_id)
				else
					nil
				end
			end
		else
			nil
		end
	end

end
