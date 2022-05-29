class AddOidc2ToOauthApplications < ActiveRecord::Migration[5.2]
  def change
    add_column :oauth_applications, :oidc_tenant_id, :string
    add_column :oauth_applications, :oidc_app_id, :string
    add_column :oauth_applications, :oidc_core_endpoint, :string
    add_column :oauth_applications, :oidc_api_secret   , :string
    add_column :oauth_applications, :oidc_verifier_id, :string
    add_column :oauth_applications, :oidc_login_proof_template_id , :string
  end
end
