class OydMailer < Devise::Mailer   
	helper :application # gives access to all helpers defined within `application_helper`.
	include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
	# default template_path: 'devise/mailer' # to make sure that your mailer uses the devise views

	def confirmation_instructions(record, token, opts={})
		I18n.with_locale(record.language) do
			if record.language == 'de'
				opts[:from] = 'Christoph von OwnYourData <oyd.email@gmail.com>'
	  			opts[:reply_to] = 'Christoph von OwnYourData <christoph@ownyourdata.eu>'
	  		else
				opts[:from] = 'Christoph from OwnYourData <oyd.email@gmail.com>'
	  			opts[:reply_to] = 'Christoph from OwnYourData <christoph@ownyourdata.eu>'
	  		end
			if record.full_name.to_s == ""
				@salutation = record.email
			else
				@salutation = record.full_name
			end
			super
		end
	end 
end