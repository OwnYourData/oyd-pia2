module Api
    module V1
        class DecsController < ApiController

            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            include ApplicationHelper
            include PluginsHelper

            # expected input for POST /api/dec112/register
            # {
            #     phone_number: wizardData.profile.phone,
            #     payload: any information provided by the user
            # }

            def register
                # validate input
                phone_number = params["phone_number"].to_s rescue ""
                if phone_number == ""
                    render json: {"error": "missing phone_number"},
                           status: 400
                    return
                end

                # ignore demo number
                if phone_number == ENV["DECTS_DEMO_NUMBER"].to_s
                    render json: {"did": "did:fake:" + ENV["DECTS_DEMO_NUMBER"].to_s },
                           status: 200
                    return
                end

                phone_hash = Base64.strict_encode64(Digest::SHA256.digest(phone_number))
                @user = User.find_by_email(phone_hash.downcase)
                if !@user.nil?
                    # return DID
                    render json: {"did": @user.did.to_s },
                           status: 200
                    return
                end
                # if !User.find_by_email(phone_hash.downcase).nil?
                #     render json: {"error": "phone number already exists"},
                #            status: 409
                #     return
                # end

                payload = params["payload"].to_json rescue ""
                if payload == ""
                    render json: {"error": "missing payload"},
                           status: 400
                    return
                end
                payload = JSON.parse(payload) rescue nil
                if payload.nil?
                    render json: {"error": "invalid payload"},
                           status: 400
                    return
                end

                # create DID
                did = "did:web:data-vault.eu:u:" + [*('a'..'z'),*('A'..'Z'),*('0'..'9'),*('_')].shuffle[0,46].join
                signing_key = Ed25519::SigningKey.generate

                # create user with phone number
                keyStr = SecureRandom.base64(64)
                keyHash = RbNaCl::Hash.sha256(keyStr.force_encoding('ASCII-8BIT'))
                unknown_private_key = RbNaCl::PrivateKey.new(keyHash)
                public_key = unknown_private_key.public_key.to_s.unpack('H*')[0]

                @user = User.new(
                    phone_hash: phone_hash,
                    phone_key: key_encrypt(keyStr, phone_number),
                    did: did,
                    did_private_key: Base58.binary_to_base58(signing_key.to_bytes),
                    password: phone_number,
                    password_confirmation: phone_number,
                    password_key: key_encrypt(keyStr, phone_number),
                    full_name: "",
                    email: phone_hash.downcase,
                    email_notif: false,
                    assist_relax: true,
                    language: "de",
                    frontend_url: ENV['VAULT_URL'].to_s)
                @user.skip_confirmation_notification!
                if !@user.save(validate: false)
                    render json: {"error": "user cannot be created"},
                           status: 500
                    return
                end
                @user.confirm

                # create key split
                shares = ShamirSecretSharing::Base58.split(secret=unknown_private_key.to_s.unpack('H*')[0], available=2, needed=2)

                # create oyd.settings repo
                @repo = Repo.new(user_id: @user.id,
                                 name: "Einstellungen",
                                 identifier: 'oyd.settings',
                                 public_key: public_key)
                retVal = @repo.save
                @repo.items.new(value: '{"value":0}').save

                # install emergency information plugin
                sam_url = "https://sam.data-vault.eu/api/plugins"
                response = HTTParty.get(sam_url + "?identifier=oyd.dec112&lang=en")
                pluginInfo = response.parsed_response rescue nil
                plugin_id = create_plugin_helper(pluginInfo, @user.id)

                # create item
                @repo = Repo.new(user_id: @user.id,
                                 name: "Dec112",
                                 identifier: 'oyd.dec112',
                                 public_key: public_key)
                retVal = @repo.save
                @item = @repo.items.new(
                            value: JSON.parse(key_encrypt(payload.to_json, keyStr))
                                        .merge({"version"=>"0.4"})
                                        .merge({"key1" => shares.first})
                                        .to_json)
                @item.save
                @item.update_attributes(value: JSON.parse(@item.value).merge({"id" => @item.id}).to_json)

                # send 2nd key part to PI2
                pi2_url = ENV['PI2_URL']
                pi2_token = getSemConToken(pi2_url, ENV["PI2_KEY"], ENV["PI2_SECRET"], "admin")
                response = HTTParty.post(pi2_url + '/api/data',
                    headers: { 'Content-Type' => 'application/json',
                               'Authorization' => 'Bearer ' + pi2_token },
                    body: [{ did: did,
                            key: shares.last }].to_json )

                if response.code.to_s == "200"
                    # return DID
                    render json: {"did": did.to_s },
                           status: 200
                else
                    render json: {"error": "PI2 error"},
                           status: 500
                end
            end

            def query
                did = params[:did].to_s
                @user = User.find_by_did(did)
                if @user.nil? || did == ""
                    render json: {"error": "DID not found"},
                           status: 404
                    return
                end
                @repo = @user.repos.where(identifier: "oyd.dec112").first
                payload = @repo.items.first.value
                render json: payload,
                       status: 200
            end

            # expected input for POST /api/dec112/register
            # {
            #     phone_number: wizardData.profile.phone,
            # }
            def revoke
                # validate input
                phone_number = params["phone_number"].to_s rescue ""
                if phone_number == ""
                    render json: {"error": "missing phone_number"},
                           status: 400
                    return
                end
                phone_hash = Base64.strict_encode64(Digest::SHA256.digest(phone_number))
                @user = User.find_by_email(phone_hash.downcase)
                if @user.nil?
                    @user = User.find_by_phone_hash(phone_hash)
                    if @user.nil?
                        render json: {"error": "phone number not found"},
                               status: 404
                    else
                        @repo = @user.repos.where(identifier: "oyd.dec112")
                        if !@repo.nil?
                            @repo.first.destroy
                            render plain: "",
                                   status: 204
                        else
                            render json: {"error": "invalid account data"},
                                   status: 500
                        end
                    end
                else
                    @user.destroy
                    render plain: "",
                           status: 204
                end
            end
        end
    end
end

