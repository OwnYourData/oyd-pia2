class ApiController < ApplicationController
	before_action :doorkeeper_authorize!
	# before_action :check_token_expiry

	# private

	# def check_token_expiry
	# 	if !doorkeeper_token.nil? && doorkeeper_token.expired?
	# 		raise ActionController::BadRequest.new('Token expired')
	# 	end
	# end
end