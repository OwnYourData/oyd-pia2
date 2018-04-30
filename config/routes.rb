Rails.application.routes.draw do
	use_doorkeeper
	devise_for :users

	# API Routes ==============
	namespace :api, defaults: { format: :json } do
		scope module: :v1,
			constraints: ApiConstraints.new(version: 1, default: true) do

				# User handling
				post 'users/create',            to: 'users#create'
				post 'users/confirm',           to: 'users#confirm'
				get  'users/show',              to: 'users#show'
				get  'users/name_by_token/:id', to: 'users#name_by_token'
				get  'users/record_count',      to: 'users#record_count'
				match 'users/current',          to: 'users#current',      via: 'get'

				# App/Plugin handling
				get   'apps/index',   to: 'apps#index'
				post  'apps/create',  to: 'apps#create'
				post  'apps/destroy', to: 'apps#destroy'
				match 'apps/:id',     to: 'apps#update', via: 'put'
				match 'apps/:id',     to: 'apps#show',   via: 'get'

				# true plugins (Doorkeeper::Application)
				match 'plugins/index',   to: 'plugins#index',   via: 'get'
				match 'plugins/current', to: 'plugins#current', via: 'get'
				match 'plugins/:id',     to: 'plugins#show',    via: 'get'
				match 'plugins/:id',     to: 'plugins#update',  via: 'put'
				match 'plugins/:id',     to: 'plugins#delete',  via: 'delete'
				match 'plugins/:id/configure', to: 'plugins#configure', via: 'post'

				# View handling
				match 'views/:id',    to: 'views#update', via: 'put'
				match 'views/:id',    to: 'views#show',   via: 'get'
				# legacy for animal mobile oyd app
				match 'modules/index', to: 'views#mobile_index', via: 'get'
				
				# Permission handling
				match 'apps/:plugin_id/perms',         to: 'perms#index',      via: 'get'
				match 'apps/:plugin_id/perms',         to: 'perms#create',     via: 'post'
				match 'apps/:plugin_id/perms/:id',     to: 'perms#update',     via: 'put'
				match 'apps/:plugin_id/perms/:id',     to: 'perms#delete',     via: 'delete'
				match 'apps/:plugin_id/perms_destroy', to: 'perms#delete_all', via: 'post'

				# Repo handling
				match 'repos/index',           to: 'repos#index',   via: 'get'
				match 'repos/:id',             to: 'repos#show',    via: 'get'
				match 'repos/:id',             to: 'repos#delete',  via: 'delete'
				match 'repos/:id/items',       to: 'repos#items',   via: 'get'
				match 'repos/:id/pub_key',     to: 'repos#pub_key', via: 'get', constraints: {id: /[^\/]+/}
				# Repos for apps
				match 'apps/:plugin_id/repos', to: 'repos#apps',    via: 'get'

				# Item handling
				match 'repos(/:repo_identifier)/items',       to: 'items#create',    via: 'post',   constraints: {repo_identifier: /[^\/]+/}
				match 'repos(/:repo_identifier)/items',       to: 'items#index',     via: 'get',    constraints: {repo_identifier: /[^\/]+/}
				match 'repos/id/:id/items',                   to: 'items#index_id',  via: 'get'
				match 'repos(/:repo_identifier)/items/:id',   to: 'items#update',    via: 'put',    constraints: {repo_identifier: /[^\/]+/}
				match 'repos(/:repo_identifier)/items/:id',   to: 'items#delete',    via: 'delete', constraints: {repo_identifier: /[^\/]+/}
				match 'repos/id/:repo_id/items/:id',          to: 'items#delete_id', via: 'delete'
				match 'items/:id/details',                    to: 'items#details',   via: 'get'
				match 'items/count', 						  to: 'items#count',     via: 'get'

				# Scheduler
				match 'tasks/index',  to: 'tasks#index',  via: 'get'
				match 'tasks/active', to: 'tasks#active', via: 'get'
				match 'tasks/create', to: 'tasks#create', via: 'post'
				match 'tasks/:id',    to: 'tasks#update', via: 'put',   constraints: {id: /[^\/]+/}
				match 'tasks/:id',    to: 'tasks#delete', via: 'delete'

				match 'reports/index', to: 'reports#index', via:  'get'
				match 'reports/:id',   to: 'reports#update', via: 'put'

				# Logs
				match 'logs/index',  to: 'logs#index',  via: 'get'
				match 'logs/create', to: 'logs#create', via: 'post'

				# Blockchain
				match 'items/merkle',   to: 'items#merkle',             via: 'get'
				match 'items/:id',      to: 'items#item_merkle_update', via: 'put'
				match 'merkles/create', to: 'items#merkle_create',      via: 'post'
				match 'merkles/:id',    to: 'items#merkle_update',      via: 'put'

		end
	end

	# Web-frontend Routes ==============
	scope "(:locale)", :locale => /en|de/ do

		# Static Pages
		root 'static_pages#home'
		get '/info', to: 'static_pages#info'
		get 'favicon', to: "static_pages#favicon"
		get '/test', to: "static_pages#test"

		# Session handling
		get    '/login',  to: 'sessions#new'
		post   '/login',  to: 'sessions#create'
		delete '/logout', to: 'sessions#destroy'

		# User handling
		get  '/user',        to: 'users#show'
		get  '/new',         to: 'users#new'
		get  '/new_account', to: 'users#new_account', constraints: { format: 'json' }
		post '/new',         to: 'users#create'
		get  '/confirm',     to: 'users#confirm'
		post '/confirm',     to: 'users#confirm_email', as: 'users_confirm_email'
		post 'update',       to: 'users#update',        as: 'users_update_account'

		# Plugin handling
		post   '/plugin/configure', to: 'apps#configure'
		delete '/plugin/remove', to: 'apps#plugin_destroy'
		get    '/plugin/detail', to: 'apps#plugin_detail', as: 'show_plugin_details'
		post   '/plugin/update', to: 'apps#plugin_update'
		get    '/plugin/:id/config', to: 'apps#plugin_config', as: 'configure_plugin'

		# App handling
		post   '/app/new',       to: 'apps#plugin_config'
		post   '/app/manifest',  to: 'apps#manifest', as: 'add_manifest'
		delete '/app/remove',    to: 'apps#destroy'
		post   '/app/update',    to: 'apps#update'
		get    '/app/detail',    to: 'apps#detail', as: 'show_app_details'
		get    '/app/detail_password', to: 'apps#detail_password', as: 'show_app_details_password'

		# Navigation - records
		match '/data',     to: 'users#data',  via: 'get'
		match '/data/:id', to: 'items#index', via: 'get', as: 'show_data'
		match '/data/:id',                         to: 'items#repo_delete', via: 'delete', as: 'repo_delete'
		match '/data/:repo_id/item/:item_id',      to: 'items#show',        via: 'get',    as: 'data_item'
		match '/data/:repo_id/item/:item_id/edit', to: 'items#edit',        via: 'get',    as: 'data_item_edit'
		match '/data/:repo_id/item/:item_id',      to: 'items#delete',      via: 'delete', as: 'data_item_delete'
		match '/account',  to: 'users#edit',    via: 'get'
		match '/decrypt',  to: 'items#decrypt', via: 'post'

		# Navigation - permission
		match '/permissions',     to: 'users#permissions',  via: 'get'

	end
	match ':not_found' => 'application#missing', :constraints => { :not_found => /.*/ }, via: [:get, :post]
end
