class ApplicationMailer < ActionMailer::Base
	default from: 'Christoph from OwnYourData <oyd.email@gmail.com>',
			reply_to: 'Christoph from OwnYourData <christoph@ownyourdata.eu>'
	layout 'mailer'
end
