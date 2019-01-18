# spec/integration/auth_spec.rb
# rake rswag:specs:swaggerize

require 'swagger_helper'

describe 'Data Vault API' do
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
								"client_secret": "empty",
								"scope": "admin" } }
				run_test!
			end
		end
	end
end
