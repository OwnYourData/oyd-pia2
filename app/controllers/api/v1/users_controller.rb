module Api
	module V1
		class UsersController < ApiController
			# respond only to JSON requests
			respond_to :json
			respond_to :html, only: []
			respond_to :xml, only: []

			include AppsHelper

			def create
				@user = User.new(
					full_name: params[:name],
					email: params[:email],
					language: params[:language],
					frontend_url: params[:frontend_url])
				if @user.save
					render json: { "user-id": @user.id }, status: 200
				else
					render json: { "error": @user.errors.full_messages }, status: 422
				end				
			end

			def key_encrypt(message, key)
				keyHash = RbNaCl::Hash.sha256(key.force_encoding('ASCII-8BIT'))
				private_key = RbNaCl::PrivateKey.new(keyHash)
				public_key = private_key.public_key
				authHash = RbNaCl::Hash.sha256('auth'.force_encoding('ASCII-8BIT'))
				auth_key = RbNaCl::PrivateKey.new(authHash)
				box = RbNaCl::Box.new(public_key, auth_key)
				nonce = RbNaCl::Random.random_bytes(box.nonce_bytes)
				msg = message.force_encoding('ASCII-8BIT')
				cipher = box.encrypt(nonce, msg)
				{ 
					value: cipher.unpack('H*')[0], 
					nonce: nonce.unpack('H*')[0]
				}.to_json
			end

			def confirm
				require 'rbnacl'
				require 'bcrypt'
				require 'securerandom'

				@user = User.where(confirmation_token: params[:token]).first
				if @user.nil?
					render json: { "error": "invalid token" }, status: 422
				else
					if @user.update(
							full_name: params[:full_name],
							password: params[:password],
							password_confirmation: params[:password_confirmation],
							recovery_password: params[:recovery_password],
							recovery_password_confirmation: params[:recovery_password_confirmation],
							recovery_password_digest: BCrypt::Password.create(params[:recovery_password]))
						if @user.valid? && @user.password_match?
							@user.confirm
							@user.update(confirmation_token: nil)

							# use password as seed for private/public key generation
							keyStr = SecureRandom.base64(64)
							keyHash = RbNaCl::Hash.sha256(keyStr.force_encoding('ASCII-8BIT'))
							unknown_private_key = RbNaCl::PrivateKey.new(keyHash)
							public_key = unknown_private_key.public_key.to_s.unpack('H*')[0]
							@repo = Repo.where(user_id: @user.id,
											   identifier: 'oyd.settings')
							if @repo.count == 0
								settings_name = "Settings"
								if @user.language == "de"
									settings_name = "Einstellungen"
								end
								@repo = Repo.new(user_id: @user.id,
												 name: "Settings",
												 identifier: 'oyd.settings',
												 public_key: public_key)
								retVal = @repo.save
								@repo.items.new(value: '{"value":0}').save
							end
							@user.update(
								password_key: key_encrypt(keyStr, params[:password]), 
								recovery_password_key: key_encrypt(keyStr, params[:recovery_password]))

							# install first beta setup
							# https://sam-en.oydapp.eu/api/plugins/1
							sam_url = "https://sam-" + @user.language + ".oydapp.eu/api/plugins/"
							params = Hash.new
							if @user.language == 'de'
								params[:source_url] = sam_url + "67"
								plugin_id = create_apps(params, @user.id)
								params[:source_url] = sam_url + "68"
								plugin_id = create_apps(params, @user.id)
								params[:source_url] = sam_url + "69"
								plugin_id = create_apps(params, @user.id)
							else 
								params[:source_url] = sam_url + "1"
								plugin_id = create_apps(params, @user.id)
								params[:source_url] = sam_url + "2"
								plugin_id = create_apps(params, @user.id)
								params[:source_url] = sam_url + "3"
								plugin_id = create_apps(params, @user.id)
							end

							render json: { "user-id": @user.id }, 
								   status: 200
						else
							render json: { "error":  @user.errors.full_messages.first }, 
								   status: 422
						end
					else
						render json: { "error": @user.errors.full_messages }, 
							   status: 422
					end
				end
			end

			def current
				if current_resource_owner.nil?
					user_id = Doorkeeper::Application.where(
						id: doorkeeper_token.application_id).first.owner_id
				else
					user_id = current_resource_owner.id
				end
				render json: User.find(user_id),
					   status: 200
			end

			def show
				if current_resource_owner.nil?
					render json: { "error": "invalid request"},
						   status: 422
				else
					render json: current_resource_owner.attributes, 
						   status: 200
				end
			end

			def name_by_token
				@user = User.find_by_confirmation_token(params[:id])
				if @user.nil?
					render json: { message: "user not found" }, 
						   status: 404
				else
					render json: { email: @user.email, 
								   full_name: @user.full_name }, 
						   status: 200
				end
			end

			def record_count
				if current_resource_owner.nil?
					user_id = Doorkeeper::Application.where(
						id: doorkeeper_token.application_id).first.owner_id
				else
					user_id = current_resource_owner.id
				end
				@user = User.find(user_id)
				if @user.nil?
					render json: { "error": "invalid token" }, status: 422
				else
					cnt = 0
					@user.repos.each{ |repo| cnt = cnt + repo.items.count }
					render json: { "count": cnt }, status: 200
				end
			end
		end
	end
end
