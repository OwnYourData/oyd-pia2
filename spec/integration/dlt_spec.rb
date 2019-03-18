# spec/integration/dlt_spec.rb
# rake rswag:specs:swaggerize

require 'swagger_helper'

describe 'Data Vault Blockchain API' do
	path '/api/items/merkle' do
		get 'list all records not yet archived in the blockchain' do
			tags 'Blockchain Verification'
			produces 'application/json'
			response '200', 'success' do
				run_test!
			end
		end
	end
	path '/api/items/{item_id}' do
		put 'update specific record in repo with blockchain reference' do
			tags 'Blockchain Verification'
			produces 'application/json'
			parameter name: :item_id, in: :path, type: :string
			parameter name: :input, in: :body
			response '200', 'success' do
				run_test!
			end
			response '404', 'not found' do
				run_test!
			end
			response '500', 'error' do
				run_test!
			end
		end
	end
	path '/api/merkles/create' do
		post 'create new merkle record' do
			tags 'Blockchain Verification'
			produces 'application/json'
			parameter name: :input, in: :body
			response '200', 'success' do
				run_test!
			end
			response '500', 'error' do
				run_test!
			end
		end
	end
	path '/api/merkles/{id}' do
		put 'update merkle record' do
			tags 'Blockchain Verification'
			produces 'application/json'
			parameter name: :id, in: :path, type: :string
			parameter name: :input, in: :body
			response '200', 'success' do
				run_test!
			end
			response '404', 'not found' do
				run_test!
			end
			response '500', 'error' do
				run_test!
			end
		end
	end
end