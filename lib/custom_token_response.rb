module CustomTokenResponse
	def body
		if !@token.resource_owner_id.nil?
		    additional_data = {
				#'userid' => @token.resource_owner_id,
				'username' => User.find(@token.resource_owner_id).full_name
		    }
		else
			user_id = Doorkeeper::Application.find(@token.application_id).owner_id
			if !user_id.nil?
				additional_data = {
					'username' => User.find(
						Doorkeeper::Application.find(
							@token.application_id).owner_id).full_name
				}
			else
				additional_data = {}
			end
		end
		super.merge(additional_data)
	end
end