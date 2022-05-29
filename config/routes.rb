Rails.application.routes.draw do
	mount Rswag::Ui::Engine => '/api-docs'
	mount Rswag::Api::Engine => '/api-docs'

	match '/oauth/authorize', to: 'oauth_applications#new',    via: 'get'
	match '/oauth/authorize', to: 'oauth_applications#create', via: 'post'

	use_doorkeeper
	devise_for :users

	# API Routes ==============
	namespace :api, defaults: { format: :json } do
		scope module: :v1,
			constraints: ApiConstraints.new(version: 1, default: true) do

				# Statistics
				match 'stats',                  to: 'stats#index',            via: 'get'

				# DEC112
				match '/dec112/register',       to: 'decs#register',          via: 'post'
				match '/dec112/query/:did',     to: 'decs#query',             via: 'get', constraints: {did: /[^\/]+/}
				match '/dec112/revoke',         to: 'decs#revoke',            via: 'delete'

				# SC Consent
				match '/consent',               to: 'consents#create',        via: 'post'
				match '/consent',               to: 'consents#index',         via: 'get'
				match '/consent/:id',           to: 'consents#show',          via: 'get'
				match '/consent/:id',           to: 'consents#update',        via: 'put'
				match '/consent/:id',           to: 'consents#delete',        via: 'delete'

				# QR Code handling
				match 'read_qr/:did',			to: 'qrs#read',               via: 'get', constraints: {did: /[^\/]+/}
				match 'connect',                to: 'qrs#qr_connect',         via: 'post'

				# App support
				match 'support/:nonce',         to: 'users#support',          via: 'get'
				match 'install/:key',           to: 'installs#show',          via: 'get'

				# User handling
				post 'users/create',            to: 'users#create'
				post 'users/confirm',           to: 'users#confirm'
				get  'users/show',              to: 'users#show'
				post 'users/do_remember',       to: 'users#do_remember'
				post 'users/remember',          to: 'users#remember'
				post 'users/forget',            to: 'users#forget'
				post 'users/update', 			to: 'users#update'
				post 'users/update_pwd',        to: 'users#update_pwd'
				post 'users/update_recv_pwd',   to: 'users#update_recv_pwd'
				get  'users/name_by_token/:id', to: 'users#name_by_token'
				get  'users/record_count',      to: 'users#record_count'
				get  'users/access_count',      to: 'users#access_count'
				match 'users/current',          to: 'users#current',          via: 'get'
				match 'users/archive',          to: 'users#archive',          via: 'get'
				match 'users/delete',           to: 'users#delete',           via: 'get'
				match 'users/app_support',      to: 'users#app_support',      via: 'post'
				match 'users/statistics',       to: 'users#statistics',       via: 'get'
				match 'users/hints',            to: 'users#hints',            via: 'get'
				match 'users/inactive_sources', to: 'users#inactive_sources', via: 'get'
				match 'users/reset_password',   to: 'users#reset_password',   via: 'post'
				match 'users/perform_password_reset', to: 'users#perform_password_reset', via: 'post'

				# App/Plugin handling
				get   'apps/index',             to: 'apps#index'
				post  'apps/destroy',           to: 'apps#destroy'
				match 'apps/:id',               to: 'apps#update', via: 'put'
				match 'apps/:id',               to: 'apps#show',   via: 'get'

				# true plugins (Doorkeeper::Application)
				match 'plugins/index',           to: 'plugins#index',           via: 'get'
				match 'plugins/create',          to: 'plugins#create',          via: 'post'
				match 'plugins/current',         to: 'plugins#current',         via: 'get'
				match 'plugins/:id',             to: 'plugins#show',            via: 'get'
				match 'plugins/:id',             to: 'plugins#update',          via: 'put'
				match 'plugins/:id',             to: 'plugins#delete',          via: 'delete'
				match 'plugins/identifier/:id',  to: 'plugins#show_identifier', via: 'get', constraints: {id: /[^\/]+/}
				# match 'plugins/:id/configure',   to: 'plugins#configure', via: 'post'
				match 'plugins/:id/manifest',    to: 'plugins#manifest_update', via: 'put'
				match  '/plugin/:id/assist',     to: 'plugins#assist',          via: 'get', constraints: {id: /[^\/]+/}
				match  '/plugin/:id/assist',     to: 'plugins#assist_update',   via: 'put', constraints: {id: /[^\/]+/}

				# Source handling
				match 'sources/index',           to: 'sources#index',     via: 'get'
				match 'sources/inactive',        to: 'sources#inactive',  via: 'get'
				match 'sources/:id',             to: 'sources#show',      via: 'get'
				match 'sources/:id',			 to: 'sources#update',    via: 'put'
				match 'sources/:id',             to: 'sources#delete',    via: 'delete'
				match 'sources/:id/configure',   to: 'sources#configure', via: 'post'
				match 'sources/:id/pile',        to: 'sources#new_pile',  via: 'post'
				match 'sources/:id/last_pile',   to: 'sources#last_pile', via: 'get'
				match 'piles/:id',               to: 'sources#show_pile', via: 'get'

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

				# Permission handling
				match 'plugins/:plugin_id/perms',         to: 'perms#index',      via: 'get'
				match 'plugins/:plugin_id/perms',         to: 'perms#create',     via: 'post'
				match 'plugins/:plugin_id/perms/:id',     to: 'perms#update',     via: 'put'
				match 'plugins/:plugin_id/perms/:id',     to: 'perms#delete',     via: 'delete'
				match 'plugins/:plugin_id/perms_destroy', to: 'perms#delete_all', via: 'post'

				# Repo handling
				match 'repos/index',           to: 'repos#index',   via: 'get'
				match 'repos/:id',             to: 'repos#show',    via: 'get'
				match 'repos(/:identifier)/identifier', to: 'repos#show_identifier', via: 'get', constraints: {identifier: /[^\/]+/}
				match 'repos/:id',             to: 'repos#delete',  via: 'delete'
				match 'repos/:id/items',       to: 'repos#items',   via: 'get'
				match 'repos/:id/count',       to: 'repos#count',   via: 'get'
				match 'repos/:id/pub_key',     to: 'repos#pub_key', via: 'get', constraints: {id: /[^\/]+/}
				# Repos for apps
				match 'apps/:plugin_id/repos', to: 'repos#apps',    via: 'get'

				# Item handling
				match 'repos/id/:id/items',                   to: 'items#index_id',  via: 'get'
				match 'repos/id/:repo_id/items/:id',          to: 'items#delete_id', via: 'delete'
				match 'repos(/:repo_identifier)/items',       to: 'items#create',    via: 'post',   constraints: {repo_identifier: /[^\/]+/}
				match 'repos(/:repo_identifier)/items',       to: 'items#index',     via: 'get',    constraints: {repo_identifier: /[^\/]+/}
				match 'repos(/:repo_identifier)/items/:id',   to: 'items#update',    via: 'put',    constraints: {repo_identifier: /[^\/]+/}
				match 'repos(/:repo_identifier)/items/:id',   to: 'items#delete',    via: 'delete', constraints: {repo_identifier: /[^\/]+/}
				match 'items/:id/details',                    to: 'items#details',   via: 'get',    as: "item_id"
				match 'dri/:dri/details',                     to: 'items#dri',       via: 'get'
				match 'items/count', 						  to: 'items#count',     via: 'get'

				# Item handling /api/data
				match '/data',                                to: 'data#index',       via: 'get'
				match '/data/:id',                            to: 'data#index',       via: 'get'
				match '/data',                                to: 'data#write',       via: 'post'
				match '/data/:id',                            to: 'data#write',       via: 'put'
				match '/data/:id', 							  to: 'data#delete',      via: 'delete'
				match '/meta/schemas',                        to: 'semantics#schema', via: 'get'
				match '/meta/tables',                         to: 'semantics#table',  via: 'get'
				match '/meta/info',                           to: 'semantics#info',   via: 'get'
				match '/meta/usage',                          to: 'users#usage',      via: 'get'
				match '/active',                              to: 'semantics#active', via: 'get'				

				#watermarking
				match 'watermark/recipients', to: 'watermarks#recipients', via: 'get'
				match 'watermark/:id',        to: 'watermarks#show',       via: 'get'
				match 'watermark/:id',        to: 'watermarks#apply',      via: 'post'

				# Scheduler
				match 'tasks/index',  to: 'tasks#index',  via: 'get'
				match 'tasks/active', to: 'tasks#active', via: 'get'
				match 'tasks/create', to: 'tasks#create', via: 'post'
				match 'tasks/:id',    to: 'tasks#update', via: 'put',   constraints: {id: /[^\/]+/}
				match 'tasks/:id',    to: 'tasks#delete', via: 'delete'

				# Answers
				match 'answers/index', to: 'answers#index', via: 'get'
				match 'answers/:id',   to: 'answers#show',  via: 'get'

				# Reports
				match 'reports/index', to: 'reports#index',  via: 'get'
				match 'reports/:id',   to: 'reports#show',   via: 'get'
				match 'reports/:id',   to: 'reports#update', via: 'put'

				# Logs
				match 'logs/index',  to: 'logs#index',  via: 'get'
				match 'logs/create', to: 'logs#create', via: 'post'

				# Blockchain
				match 'items/merkle',   to: 'items#merkle',             via: 'get'
				match 'items/:id',      to: 'items#item_merkle_update', via: 'put'
				match 'merkles/create', to: 'items#merkle_create',      via: 'post'
				match 'merkles/:id',    to: 'items#merkle_update',      via: 'put'

				# News
				match 'news', to: 'news#current', via: 'get'

				# Sharing & Watermarking
				match 'share_data',     to: 'sharings#create',          via: 'post'

				# Relations
				match 'relation', to: 'relations#index', via: 'get'
				match 'relation', to: 'relations#create', via: 'post'

				# eIDAS signing
				match 'eidas',       to: 'eidas#create', via: 'post'
				match 'eidas/token', to: 'eidas#token',  via: 'post'
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
		get    '/login',  to: 'static_pages#home'
		post   '/login',  to: 'sessions#create'
		delete '/logout', to: 'sessions#destroy'
		get    '/logout',  to: 'sessions#destroy'
		match '/phone_login',      to: 'static_pages#phone',     via: 'get'
		match '/phone_code',       to: 'static_pages#code',      via: 'get'
		match '/phone_code',       to: 'static_pages#code',      via: 'post'
		match '/oidc',             to: 'sessions#oidc',          via: 'get'

		# User handling
		get  '/user',              to: 'users#show'
		get  '/new',               to: 'users#new'
		get  '/new_account',       to: 'users#new_account', constraints: { format: 'json' }
		post '/new',               to: 'users#create'
		get  '/confirm',           to: 'users#confirm'
		post '/confirm',           to: 'users#confirm_email', as: 'users_confirm_email'
		post 'update',             to: 'users#update',        as: 'users_update_account'
		post 'updatePwd',          to: 'users#updatePwd',     as: 'users_update_password'
		post 'updateRecvPwd',      to: 'users#updateRecvPwd', as: 'users_update_recovery_password'
		match '/password_reset',   to: 'users#password_reset',   via: 'get'
		match '/reset_password',   to: 'users#reset_password',   via: 'post'
		match '/confirm_reset',    to: 'users#confirm_reset',    via: 'get'
		match '/perform_password_reset', to: 'users#perform_password_reset', via: 'post'
		match '/archive_decrypt',  to: 'users#archive_decrypt',  via: 'post'
		match '/user_archive',     to: 'users#user_archive',     via: 'get', defaults: { format: 'json' }
		match '/pia_delete',       to: 'users#pia_delete',       via: 'post'

		# OIDC handling
		match '/login_sowl',       to: 'sessions#login_sowl',    via: 'get'
		match 'signin-oidc',       to: 'application#oidc',       via: 'get'

		# Plugin handling
		match  '/plugins',           to: 'users#plugins',        via: 'get'
		post   '/plugin/configure',  to: 'apps#configure'
		delete '/plugin/remove',     to: 'apps#plugin_destroy'
		get    '/plugin/detail',     to: 'apps#plugin_detail',   as: 'show_plugin_details'
		post   '/plugin/update',     to: 'apps#plugin_update'
		get    '/plugin/:id/config', to: 'apps#plugin_config',   as: 'configure_plugin'
		get    '/plugin/:id/update', to: 'apps#manifest_update', as: 'update_plugin'
		get    '/plugins/code/:id',  to: 'apps#connection_key',  as: 'request_key'

		# App handling
		post   '/app/new',       to: 'apps#plugin_config'
		post   '/app/manifest',  to: 'apps#manifest', as: 'add_manifest'
		delete '/app/remove',    to: 'apps#destroy'
		post   '/app/update',    to: 'apps#update'
		get    '/app/detail',    to: 'apps#detail', as: 'show_app_details'
		get    '/app/detail_password', to: 'apps#detail_password', as: 'show_app_details_password'

		# Navigation - records
		match '/data',     to: 'users#data',       via: 'get'
		match '/data/:id', to: 'items#index',      via: 'get', as: 'show_data'
		match '/data/:id',                         to: 'items#repo_delete', via: 'delete', as: 'repo_delete'
		match '/data/:repo_id/item/:item_id',      to: 'items#show',        via: 'get',    as: 'data_item'
		match '/data/:repo_id/item/:item_id/edit', to: 'items#edit',        via: 'get',    as: 'data_item_edit'
		match '/data/:repo_id/item/:item_id',      to: 'items#delete',      via: 'delete', as: 'data_item_delete'
		match '/account',  to: 'users#edit',       via: 'get'
		match '/decrypt',  to: 'items#decrypt',    via: 'post'

		# Source handling
		match '/sources',          to: 'users#sources',   via: 'get'
		match '/sources/remove',   to: 'sources#destroy', via: 'delete'
		match '/sources/:id/edit', to: 'sources#edit',    via: 'get',   as: 'configure_source'
		match '/sources/update',   to: 'sources#update',  via: 'post'

		# Access Log
		match '/log', 			   to: 'logs#index',      via: 'get'

		# OYD Assistant
		match '/hide_assist', to: 'users#hide_assist', via: 'post', as: 'hide_assist'

		# Knowledge Graph
		match '/show_kg', to: 'users#show_kg', via: 'post'

		# access from external applications
		match '/external/gmaps_analysis/register', to: 'static_pages#gmaps', via: 'get'

	end

	# did:web
	match '/u/:did',          to: 'dids#show', via: 'get', defaults: { format: 'json' }
	match '/u/:did/did.json', to: 'dids#show', via: 'get', defaults: { format: 'json' }

	# SemCon Connect
	match '/connect',         to: 'connections#create', via: 'post'

	match ':not_found' => 'application#missing', :constraints => { :not_found => /.*/ }, via: [:get, :post]
end
