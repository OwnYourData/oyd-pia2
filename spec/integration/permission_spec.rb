# spec/integration/permission_spec.rb
# rake rswag:specs:swaggerize

require 'swagger_helper'

describe 'Permission API' do
	path '/api/plugins/{plugin_id}/perms' do
		get 'list all permission for the specific plugin' do
			tags 'Permission Management'
			produces 'application/json'
			parameter name: :plugin_id, in: :path, type: :integer
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
	path '/api/plugins/{plugin_id}/perms' do
		post 'create a new permission for the specified plugin' do
			tags 'Permission Management'
			produces 'application/json'
			parameter name: :plugin_id, in: :path, type: :string
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
	path '/api/plugins/{plugin_id}/perms/{id}' do
		put 'update specified permission for the specified plugin' do
			tags 'Permission Management'
			produces 'application/json'
			parameter name: :plugin_id, in: :path, type: :string
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
	path '/api/plugins/{plugin_id}/perms/{id}' do
		delete 'delete specified permission for the specified plugin' do
			tags 'Permission Management'
			produces 'application/json'
			parameter name: :plugin_id, in: :path, type: :string
			parameter name: :id, in: :path, type: :string
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
	path '/api/plugins/{plugin_id}/perms_destroy' do
		delete 'delete all permissions for the specified plugin' do
			tags 'Permission Management'
			produces 'application/json'
			parameter name: :plugin_id, in: :path, type: :string
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