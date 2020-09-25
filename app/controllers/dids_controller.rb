class DidsController < ApplicationController
    include ApplicationHelper
    def show
        did = params[:did].to_s
        did_ = did.split(":").last rescue ""
        if did_ == ""
            render json: {"error": "invalid DID"}, 
                   status: 404
            return
        end
        @user = User.find_by_did("did:web:data-vault.eu:u:" + did_.to_s)
        if @user.nil?
            render json: {"error": "DID not found"}, 
                   status: 404
            return
        end

        signing_key = Ed25519::SigningKey.new(Base58.base58_to_binary(@user.did_private_key)) rescue nil?
        if signing_key.nil?
            render json: {"error": "invalid DID"}, 
                   status: 404
            return
        end

        verify_key = signing_key.verify_key

# === did Key-Section ===
# possible Signature Keys: https://w3c-ccg.github.io/security-vocab/
# "publicKey": [{
#     "id": "#key-1",
#     "type": "Secp256k1VerificationKey2018",
#     "publicKeyJwk": {
#         "kty": "EC",
#         "kid": "#key-1",
#         "crv": "P-256K",
#         "x": "j23-trviZytibbYLKND7YR8CYwUAFMYS9PNAaqdSI3k",
#         "y": "c7oo1QLOczTP7jbMwmdE9nr64TkuIJTfRuhYYWaKVdQ",
#         "use": "verify",
#         "defaultEncryptionAlgorithm": "none",
#         "defaultSignAlgorithm": "ES256K"
#     },
#     "usage": "signing"
# }
#
#     "@context": ["https://w3id.org/security/v1"],


        my_did = JSON.parse('{
"@context": "https://w3id.org/did/v1",
"id": "did:web:data-vault.eu:u:' + did_ + '",
"publicKey": [{
    "id": "did:web:data-vault.eu:u:' + did_ + '#key-1",
    "type": "Ed25519VerificationKey2018",
    "controller": "did:web:data-vault.eu:u:' + did_ + '",
    "expires": "' + (Time.now+2.years).utc.iso8601 + '",
    "publicKeyBase58": "' + Base58.binary_to_base58(verify_key.to_bytes) + '"
}],
"service": [{
    "id": "PersonalInfo",
    "type": "AgentService",
    "serviceEndpoint": {
        "@type": "UserServiceEndpoint",
        "instance": ["https://data-vault.eu/api/dec112/query"]
    }
}]
}')

        send_data(my_did.to_json, type: :json, disposition: "attachment", filename: "did.json")
    end
end
