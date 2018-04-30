class PermType < ActiveRecord::Base
	READ = 1
	WRITE = 2
	UPDATE = 3
	DELETE = 4
end