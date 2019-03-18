# spec/integration/dlt_spec.rb
# rake rswag:specs:swaggerize

require 'swagger_helper'

describe 'Data Vault Plugins API' do
	path '/api/plugins/index' do
		get 'get list of installed plugins for current user' do
			tags 'Plugins'
			produces 'application/json'
			response '200', 'success' do
				run_test!
			end
		end
	end
	path '/api/plugins/create' do
		post 'create new plugin' do
			tags 'Plugins'
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
	path '/api/plugins/{plugin_id}' do
		get 'get plugin information' do
			tags 'Plugins'
			produces 'application/json'
			parameter name: :plugin_id, in: :path, type: :string
			response '200', 'success' do
				run_test!
			end
			response '403', 'permission denied' do
				run_test!
			end
		end
		put 'update plugin information' do
			tags 'Plugins'
			produces 'application/json'
			parameter name: :plugin_id, in: :path, type: :string
			parameter name: :input, in: :body
			response '200', 'success' do
				run_test!
			end
			response '403', 'permission denied' do
				run_test!
			end
		end
		delete 'delete plugin' do
			tags 'Plugins'
			produces 'application/json'
			parameter name: :plugin_id, in: :path, type: :string
			response '200', 'success' do
				run_test!
			end
			response '403', 'permission denied' do
				run_test!
			end
		end
	end
end
