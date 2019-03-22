class OydMailer < Devise::Mailer   
	helper :application # gives access to all helpers defined within `application_helper`.
	include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
	# default template_path: 'devise/mailer' # to make sure that your mailer uses the devise views

	def confirmation_instructions(record, token, opts={})
		I18n.with_locale(record.language) do
			if record.language == 'de'
				opts[:from] = 'Christoph von OwnYourData <oyd.email@gmail.com>'
	  			opts[:reply_to] = 'Christoph von OwnYourData <christoph@ownyourdata.eu>'
	  			opts[:subject] = "Nur mehr ein Schritt zu deinem Datentresor (OwnYourData)"
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

	def password_reset(opts={})
		@user = params[:user]
		@token = params[:token]
		if @user.language == 'de'
			I18n.with_locale('de') do
				mail(to: @user.email, 
					 from: 'Christoph von OwnYourData <oyd.email@gmail.com>',
					 reply_to: 'Christoph von OwnYourData <christoph@ownyourdata.eu>',
					 subject: "[OwnYourData] Passwort zurücksetzen")
			end
		else
			I18n.with_locale('en') do
				mail(to: @user.email, 
					 from: 'Christoph from OwnYourData <oyd.email@gmail.com>',
					 reply_to: 'Christoph from OwnYourData <christoph@ownyourdata.eu>',
					 subject: "[OwnYourData] Reset Password")
			end
		end
	end

end