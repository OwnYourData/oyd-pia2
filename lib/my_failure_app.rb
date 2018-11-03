class MyFailureApp < Devise::FailureApp
	def respond
		self.status = 401
		self.content_type = 'application/json'
		self.response_body = '{"error": "unauthorized"}'
	end
end