# spec/integration/data_spec.rb
# rake rswag:specs:swaggerize

require 'swagger_helper'

describe 'Data Vault Read/Write API' do
	path '/api/repos/{repo_id}/items' do
		get 'read all records in repo' do
			tags 'Read/Write Data'
			produces 'application/json'
			parameter name: :repo_id, in: :path, type: :string
			response '200', 'success' do
				run_test!
			end
			response '403', 'Permission denied' do
				run_test!
			end
		end
		post 'create new record in repo' do
			tags 'Read/Write Data'
			produces 'application/json'
			parameter name: :repo_id, in: :path, type: :string
			parameter name: :input, in: :body
			response '200', 'success' do
				run_test!
			end
			response '403', 'Permission denied' do
				run_test!
			end
		end
	end
	path '/api/items/{item_id}/details' do
		get 'read specific record' do
			tags 'Read/Write Data'
			produces 'application/json'
			parameter name: :item_id, in: :path, type: :string
			response '200', 'success' do
				run_test!
			end
			response '403', 'Permission denied' do
				run_test!
			end
		end
	end
	path '/api/repos/{repo_id}/items/{item_id}' do
		put 'update specific record in repo' do
			tags 'Read/Write Data'
			produces 'application/json'
			parameter name: :repo_id, in: :path, type: :string
			parameter name: :item_id, in: :path, type: :string
			parameter name: :input, in: :body
			response '200', 'success' do
				run_test!
			end
			response '403', 'Permission denied' do
				run_test!
			end
		end
		delete 'delete specific record in repo' do
			tags 'Read/Write Data'
			produces 'application/json'
			parameter name: :repo_id, in: :path, type: :string
			parameter name: :item_id, in: :path, type: :string
			response '200', 'success' do
				run_test!
			end
			response '403', 'Permission denied' do
				run_test!
			end
		end
	end
end