module Api
    module V1
        class SharingsController < ApiController
            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            include ApplicationHelper

            def create
                user_id = Doorkeeper::Application.find(doorkeeper_token.application_id).user.id rescue nil

                survey_data = JSON.parse(params["survey"].to_json) rescue nil
                series_data = JSON.parse(params["series"].to_json) rescue nil

                # check survey data ===========
                if survey_data.nil? || series_data.nil?
                    render json: {"error": "invalid data format"},
                           status: 400
                    return
                end
                survey_id = survey_data["id"]
                @survey = Item.find(survey_id) rescue nil
                if @survey.nil?
                    render json: {"error": "survey_id not found"},
                           status: 404
                    return
                end
                uid = @survey.repo.user.id rescue ""
                if uid != user_id
                    render json: {"error": "permission denied"},
                           status: 401
                    return
                end

                # get DID
                did = survey_data["survey_meta"]["did"] rescue ""
                if did.to_s == ""
                    render json: {"error": "invalid DID"},
                           status: 400
                end

                # check series data ===========
                cnt = 0
                series_data.each do |time_series|
                    time_series["series"].each do |item|
                        id = item["id"]
                        cnt += 1
                        @el = Item.find(id) rescue nil
                        if @el.nil?
                            render json: {"error": "invalid time series data"},
                                   status: 404
                            return
                        end
                        if @el.repo.user.id != uid
                            render json: {"error": "permission denied"},
                                   status: 403
                            return
                        end
                    end
                end
                if cnt == 0
                    render json: {"error": "missing time series data"},
                           status: 400
                    return
                end

                # split up time series in monthly slices ========
                # and create entries in OydRecipient, apply watermarking, and
                # create relations
                share_data = survey_data.except("id", "survey_meta").stringify_keys
                vitalSigns = []
                series_data.each do |time_series|
                    months = []
                    ids = {}
                    time_series["series"].each do |item|
                        id = item["id"]
                        OydRelation.new(
                            source_id: survey_id,
                            target_id: id).save
                        key = Date.parse(item["content"]["effectiveDateTime"]).strftime("%m-%Y") rescue nil
                        if !key.nil?
                            months << key
                            monthy = months.uniq
                            if ids.key?(key)
                                ids[key] << id
                            else
                                ids[key] = [id]
                            end
                        end
                    end
                    if months.length > 0
                        errors = {}
                        months.each do |fragment|
                            @oydr = OydRecipient.where(
                                user_id: user_id,
                                source_id: survey_id,
                                recipient_did: did,
                                fragment_identifier: fragment)
                            if @oydr.nil? || @oydr.count == 0
                                @oydr = OydRecipient.new(
                                    user_id: user_id,
                                    source_id: survey_id,
                                    recipient_did: did,
                                    fragment_identifier: fragment,
                                    fragment_array: ids[fragment].to_s,
                                    key: rand(10e8).to_i
                                )
                                @oydr.save
                            else
                                @oydr = @oydr.first
                                @oydr.update_attributes(fragment_array: ids[fragment].to_s)
                            end

                            error_length = ids[fragment].length
                            srand(@oydr.key.to_i)
                            err_vec = []
                            error_length.times{ err_vec << (rand - 0.5)/2 }
                            errors[fragment] = err_vec
                        end
                    end
                    i = 0
                    time_series["series"].each do |item|
                        content = item["content"]
                        fragment = Date.parse(content["effectiveDateTime"]).strftime("%m-%Y")
                        val = content["valueQuantity"].to_f + errors.stringify_keys[fragment][i]
                        content["valueQuantity"] = sprintf('%.2f', val)
                        vitalSigns << content
                        i += 1
                    end
                end
                share_data["content"]["vitalSignsPayload"] = vitalSigns


                # send data to sharing endpoint ==========
                # and store consent information
                sharing_url = "https://dip-sharing.data-container.net/api/data"
                sharing_host = "https://dip-sharing.data-container.net"
                share_uid = "c075eea8a59e2fad56122116517f59ed1e418077d294b95a34af5a61cf3bd114"
                share_secret = "a2a147e596b88145d275fdef43c984af70187c9f87f7bb5bf4515208649bfbcf"

                token = getSemConToken(sharing_host, share_uid, share_secret, "write")
                response = HTTParty.post(sharing_url,
                    headers: { 'Content-Type' => 'application/json',
                               'Authorization' => 'Bearer ' + token },
                    body: share_data.to_json )

                consent_rec = {
                    "timestamp": Time.now.getutc.to_i,
                    "service-endpoint": response.parsed_response["serviceEndpoint"],
                    "service-description": "data sharing",
                    "identifier": did,
                    "usage-policy": survey_data["survey_meta"]["controller_usage_policy"],
                    "receipt": response.parsed_response,
                    "repo_identifier": "oyd.consent"
                }.stringify_keys rescue {}

                @user = User.find(user_id)
                @repo = @user.repos.where(identifier: "oyd.consent").first rescue nil
                plugin_id = @user.oauth_applications.where(identifier: "dev.unterholzer.ownyourdata.sharing").first.id rescue nil
                retVal = create_item(@repo, user_id, consent_rec, plugin_id)

                render plain: "", 
                       status: 200
            end
        end
    end
end