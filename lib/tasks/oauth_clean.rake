desc "Trim old OAuth tokens from the tables (default: > 5 days)."
task :trim_doorkeeper_tokens => :environment do
  delete_before = (ENV["DOORKEEPER_DAYS_TRIM_THRESHOLD"] || 5).to_i.days.ago
  expire = [
    "(revoked_at IS NOT NULL AND revoked_at < :delete_before) OR " +
    "(expires_in IS NOT NULL AND (created_at + expires_in * INTERVAL '1 second') < :delete_before)",
    { :delete_before => delete_before },
  ]
  Doorkeeper::AccessGrant.where(expire).delete_all
  Doorkeeper::AccessToken.where(expire).delete_all
end