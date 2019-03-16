# spec/integration/auth_spec.rb
# rake rswag:specs:swaggerize

require 'swagger_helper'

describe 'Data Vault Authentication API' do
	path '/oauth/token' do
		post 'request token' do
			before do
				@app = Doorkeeper::Application.new name: "test", redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
				@app.save!
			end
			tags 'Authorization'
			consumes 'application/json'
			parameter name: :input, in: :body
			response '200', 'success' do
				let(:input) { { "grant_type": "client_credentials", 
								"client_id": @app.uid,
								"client_secret": @app.secret } }
				run_test! do |response|
					data = JSON.parse(response.body)
					expect(data["access_token"].to_s.length).to eq(64)
				end
			end
			response '401', 'invalid' do
				let(:input) { { "grant_type": "client_credentials", 
								"client_id": "invalid",
								"client_secret": "empty" } }
				run_test!
			end
		end
	end

	path '/oauth/token/info' do
		get 'show token information' do
			before do
				@app = Doorkeeper::Application.new name: "test", redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
				@app.save!
				@token = Doorkeeper::AccessToken.new application_id: @app.id
				@token.save!
			end
			tags 'Authorization'
			produces 'application/json'
			parameter({
				:in => :header,
				:type => :string,
				:name => :Authorization,
				:required => true,
				:description => 'Client token' })
			response '200', 'success' do
				let(:Authorization) { "Bearer " + @token.token.to_s }
				run_test!
			end
			response '401', 'invalid request' do
				let(:Authorization) { "Bearer invalid" }
				run_test!
			end
		end
	end

	path '/oauth/revoke' do
		post 'revoke token' do
			before do
				@app = Doorkeeper::Application.new name: "test", redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
				@app.save!
				@token = Doorkeeper::AccessToken.new application_id: @app.id
				@token.save!
			end
			tags 'Authorization'
			consumes 'application/json'
			parameter name: :input, in: :body
			response '200', 'success' do
				let(:input) { { "token": @token.token } }
				run_test!
			end
			response '404', 'not found' do
				let(:input) { { "token": "invalid" } }
				run_test!
			end
		end
	end

	path '/oauth/applications' do
		post 'create plugin' do
			before do
				@app = Doorkeeper::Application.new name: "test", redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
				@app.save!
				@token = Doorkeeper::AccessToken.new application_id: @app.id
				@token.save!
			end
			tags 'Authorization'
			consumes 'application/json'
			produces 'application/json'
			parameter({ :in => :header,
						:type => :string,
						:name => :Authorization,
						:required => true,
						:description => 'Client token' })
			parameter({ :in => :body,
					    :name => :input,
					    :schema => {
					    	type: :object,
					    	properties: {
					    		name: { type: :string }
					    	},
					    	required: [ 'name' ]
					    } })
			response '200', 'success' do
				ENV["AUTH"] = "true"
				let(:Authorization) { "Bearer " + @token.token.to_s }
				let(:input) { { "name": "app2" } }
				run_test! do |response|
					expect(Doorkeeper::Application.count).to eq(2)
				end
			end

			response '401', 'invalid token' do
				let(:Authorization) { "Bearer invalid" }
				let(:input) { { "name": "app3" } }
				run_test! do |response|
					expect(Doorkeeper::Application.count).to eq(1)
				end
			end

		end
	end

	path '/oauth/applications/{id}' do
		delete 'remove plugin' do
			before do
				@app = Doorkeeper::Application.new name: "test", redirect_uri: "urn:ietf:wg:oauth:2.0:oob"
				@app.save!
				@token = Doorkeeper::AccessToken.new application_id: @app.id
				@token.save!
			end
			tags 'Authorization'
			produces 'application/json'
			parameter({ :in => :header,
						:type => :string,
						:name => :Authorization,
						:required => true,
						:description => 'Client token' })
			parameter({ :name => :id, 
				        :in => :path, 
				        :type => :string,
						:description => "'id' of account" })
			response '200', 'success' do
				let(:Authorization) { "Bearer " + @token.token.to_s }
				let(:id) { @app.id }
				run_test! do |response|
					expect(Doorkeeper::Application.count).to eq(0)
				end
			end
			response '401', 'invalid token' do
				let(:Authorization) { "Bearer invalid" }
				let(:id) { @app.id }
				run_test! do |response|
					expect(Doorkeeper::Application.count).to eq(1)
				end
			end
			response '404', 'not found' do
				let(:Authorization) { "Bearer " + @token.token.to_s }
				let(:id) { -1 }
				run_test! do |response|
					expect(Doorkeeper::Application.count).to eq(1)
				end
			end
		end
	end

end