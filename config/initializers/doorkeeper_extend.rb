doorkeeper_extend_dir = File.join(Rails.root, "app", "models", "doorkeeper")
Dir.glob("#{doorkeeper_extend_dir}/*.rb").each { |f| require(f) }