class ApiController < ApplicationController
	before_action -> { doorkeeper_authorize! unless :name_by_token}
end