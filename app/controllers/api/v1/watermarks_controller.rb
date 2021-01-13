module Api
    module V1
        class WatermarksController < ApiController
            include WatermarkHelper

            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            # GET /api/watermark/recipients
            # return all records of OydRecipient for the current user
            def recipients

                render json: {"hello": "world"},
                       status: 200
            end

            # GET /api/watermark/:id
            # return all records specified by the element in OydRecipient
            def show

                render json: {"hello": "world"},
                       status: 200
            end

            # POST /api/watermark/:id
            # apply the respective watermarking to the data provided
            def apply

                render json: {"hello": "world"},
                       status: 200
            end


            # GET /api/data/fragment/:fragment_id
            # return specified (watermarked) data fragment
            def account_fragment
                account_id = doorkeeper_token.application_id
                fragment_id = params[:fragment_id].to_s rescue nil
                if !valid_fragment?(fragment_id)
                    render json: {"error": "invalid fragment_id"}.to_json,
                           status: 422
                    return
                end

                key = get_fragment_key(fragment_id, account_id)
                data = get_fragment(fragment_id)
                retVal = apply_watermark(data, key)
                render json: retVal, 
                       status: 200
            end

            # GET /api/watermark
            # return all data watermarked for the current user
            def account_data
                account_id = params[:account_id].to_i rescue nil
                if !valid_account?(account_id)
                    render json: {"error": "invalid account_id"}.to_json,
                           status: 422
                    return
                end
                retVal = []
                all_fragments("").each do |fragment_id|
                    key = get_fragment_key(fragment_id, account_id)
                    data = get_fragment(fragment_id)
                    retVal += apply_watermark(data, key)
                end
                render json: retVal, 
                       status: 200
            end

            # GET /api/watermark/fragment/:fragment_id/error
            # return error vector for specified fragment
            def account_fragment_error
                account_id = params[:account_id].to_i rescue nil
                if !valid_account?(account_id)
                    render json: {"error": "invalid account_id"}.to_json,
                           status: 422
                    return
                end

                fragment_id = params[:fragment_id].to_s rescue nil
                if !valid_fragment?(fragment_id)
                    render json: {"error": "invalid fragment_id"}.to_json,
                           status: 422
                    return
                end

                key = get_fragment_key(fragment_id, account_id)
                data = get_fragment(fragment_id)
                retVal = error_vector(key, data)
                render json: retVal.to_json, 
                       status: 200
            end

            # GET /api/watermark/fragment/:fragment_id/kpi/:kpi
            # return error vector for specified fragment and account
            def account_fragment_kpi
                require 'enumerable/standard_deviation'

                account_id = params[:account_id].to_i rescue nil
                if !valid_account?(account_id)
                    if account_id.to_s != "0"
                        render json: {"error": "invalid account_id"}.to_json,
                               status: 422
                        return
                    end
                end

                fragment_id = params[:fragment_id].to_s rescue nil
                if !valid_fragment?(fragment_id)
                    render json: {"error": "invalid fragment_id"}.to_json,
                           status: 422
                    return
                end

                data = get_fragment(fragment_id)
                if account_id.to_s != "0"
                    key = get_fragment_key(fragment_id, account_id)
                    data = apply_watermark(data, key)
                end
                vals = data.map { |i| JSON(i["item"])["value"] }

                case params[:kpi].to_s
                when "mean"
                    retVal = {"mean": vals.mean}
                when "stdv"
                    retVal = {"standard deviation": vals.standard_deviation}
                else
                    render json: {"error": "unknown kpi"}.to_json,
                           status: 404
                    return
                end
                render json: retVal.to_json, 
                       status: 200
            end

            # GET /api/watermark/error/:key(/:len)
            # return error vector for specified key and optional length
            def key
                if params[:len].to_s == ""
                    key_length = default_key_length()
                else
                    key_length = Integer(params[:len].to_s) rescue 100
                end
                retVal = error_vector(params[:key].to_s, key_length.times.map{1})
                render json: retVal.to_json, 
                       status: 200
            end

            # GET /api/watermark/fragments
            # return list of fragment identifiers and associated keys
            def fragments_list
                retVal = Watermark.select(:account_id, :fragment, :key).order("account_id ASC, fragment ASC").to_json(:except => :id)
                render json: retVal, 
                       status: 200
            end

            # GET /api/watermark/fragment/:fragment_id
            # return specified (not watermarked) data fragment
            def raw_data
                retVal = get_fragment(params[:fragment_id].to_s)
                render json: retVal.to_json, 
                       status: 200
            end

            # POST /api/watermark/identify
            # body: one fragment of a suspicious dataset
            # return descending sorted list of fragment identifiers with distance for each value
            def identify
                input = JSON(request.body.read) rescue nil

                if input.nil?
                    render json: {"error": "invalid JSON"},
                           status: 422
                    return
                end

                input_vals = input.map { |i| i["value"] }
                retVal = []
                all_fragments("").each do |fragment_id|
                    fragment_vals = get_fragment(fragment_id).map { |i| JSON(i["item"])["value"] }
                    dist, similarity = distance(input_vals, fragment_vals) 
                    retVal << { "fragment": fragment_id, 
                                "size": fragment_vals.length,
                                "distance": dist,
                                "similarity": similarity }
                end
                render json: { "input": {"size": input_vals.length},
                               "identify": retVal.sort_by { |i| i[:distance] } }, 
                       status: 200
            end

            # POST /api/watermark/fragment/:fragment_id 
            # body: one fragment of a suspicious dataset
            # return distance between provided fragment and watermarked fragment
            def compare
                input = JSON(request.body.read) rescue nil
                if input.nil?
                    render json: {"error": "invalid JSON"},
                           status: 422
                    return
                end
                input_vals = input.map { |i| i["value"] }

                fragment_id = params[:fragment_id].to_s rescue nil
                if !valid_fragment?(fragment_id)
                    render json: {"error": "invalid fragment_id"}.to_json,
                           status: 422
                    return
                end

                account_id = params[:account_id].to_i rescue nil
                if account_id == 0
                    accounts = []
                    data = get_fragment(fragment_id)
                    fragment_size = 0
                    Doorkeeper::Application.pluck(:id).each do |account_id|
                        key = get_fragment_key(fragment_id, account_id)
                        account_data = apply_watermark(data, key)
                        fragment_vals = account_data.map { |i| i["item"]["value"] }
                        fragment_size = fragment_vals.length
                        dist, similarity = distance(input_vals, fragment_vals)
                        accounts << {
                            "id": account_id,
                            "distance": dist,
                            "similarity": similarity
                        }

                    end

                    retVal = {
                        "input": {
                            "size": input_vals.length,
                            "fragment": fragment_id,
                            "fragment-size": fragment_size
                        },
                        "accounts": accounts.sort_by { |i| i[:distance] }
                    }
                    render json: retVal, 
                           status: 200

                else
                    if !valid_account?(account_id)
                        render json: {"error": "invalid account_id"}.to_json,
                               status: 422
                        return
                    end
                    data = get_fragment(fragment_id)
                    key = get_fragment_key(fragment_id, account_id)
                    data = apply_watermark(data, key)
                    fragment_vals = data.map { |i| i["item"]["value"] }

                    dist, similarity = distance(input_vals, fragment_vals)
                    retVal = {
                        "input": {
                            "size": input_vals.length,
                            "fragment": fragment_id,
                            "fragment-size": fragment_vals.length
                        },
                        "accounts": [{
                            "id": account_id,
                            "distance": dist,
                            "similarity": similarity
                        }]
                    }
                    render json: retVal, 
                           status: 200
                end
            end
        end
    end
end