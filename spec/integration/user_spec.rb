# spec/integration/dlt_spec.rb
# rake rswag:specs:swaggerize

require 'swagger_helper'

describe 'Data Vault User Management API' do
	path '/api/users/show' do
		get 'get information from current user' do
			tags 'User Management'
			produces 'application/json'
			response '200', 'success' do
				run_test!
			end
			response '422', 'invalid request' do
				run_test!
			end
		end
	end
	path '/api/users/create' do
		post 'create new user' do
			tags 'User Management'
			produces 'application/json'
			parameter name: :input, in: :body
			response '200', 'success' do
				run_test!
			end
			response '400', 'error' do
				run_test!
			end
		end
	end
	path '/api/users/update' do
		put 'update current user information' do
			tags 'User Management'
			produces 'application/json'
			parameter name: :input, in: :body
			response '200', 'success' do
				run_test!
			end
			response '422', 'invalid request' do
				run_test!
			end
			response '500', 'error' do
				run_test!
			end
		end
	end
	path '/api/users/delete' do
		delete 'delete current user' do
			tags 'User Management'
			produces 'application/json'
			response '200', 'success' do
				run_test!
			end
			response '500', 'error' do
				run_test!
			end
		end
	end
end