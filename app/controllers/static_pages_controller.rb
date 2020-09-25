class StaticPagesController < ApplicationController
    include ApplicationHelper
    def home
        if logged_in?
            redirect_to user_path
        end
    end

    def info
    end

    def gmaps
    end

    def phone
    end

    def code
        @phone_number = params[:phone_number].to_s
        if request.post?
            redirect_to phone_code_path(phone_number: @phone_number)
            return
        end
        secret_code = (SecureRandom.random_number(9e5) + 1e5).to_i
        secret_code_text = secret_code.to_s + " " + oyd_backend_translate("secret_code", params[:locale])
        response_nil = false
        sms_url = "https://www.firmensms.at/gateway/senden.php"
        # sms_url = "https://www.firmensms.at/gateway/rest/"
        # auth_bearer = Base64.strict_encode64(ENV["SMS_USER"].to_s + ":"  + ENV["SMS_PWD"].to_s) rescue ""
        # hdr = { 'Accept' => '*/*',
        #         'Content-Type' => 'application/json',
        #         'Authorization' => 'Bearer ' + auth_bearer }
        # body = { 'route' => 3,
        #          'to' => @phone_number, 
        #          'text' => secret_code_text,
        #          'senderid' => "OwnYourData",
        #          'test' => 0,
        #          'deliveryreport' => 1 }
        body = "id=" + ENV["SMS_USER"].to_s
        body += "&pass=" + ENV["SMS_PWD"].to_s
        body += "&nummer=" + @phone_number.to_s
        body += "&absender=OwnYourData"
        body += "&route=3"
        body += "&text=" + secret_code_text.to_s
        begin
            response = HTTParty.post(sms_url, body: body )
        rescue => ex
            response_nil = true
        end
        if !response_nil && !response.body.nil? && response.code == 200
            @user = User.find_by_email(Base64.strict_encode64(Digest::SHA256.digest(@phone_number)).downcase)
            if !@user.nil?
                @user.update_attribute("sms_code", secret_code.to_s)
            end
        else
            flash[:warning] = oyd_backend_translate("sms_error", params[:locale])
            redirect_to login_path
            return
        end

    end

    def favicon
        send_file 'public/favicon.ico', type: 'image/x-icon', disposition: 'inline'
    end

    def test
    end
    
end
