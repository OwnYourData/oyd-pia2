class ItemsController < ApplicationController
    include ApplicationHelper
    include SessionsHelper

    before_action :logged_in_user

    def index
        token = session[:token]
        repo_url = getServerUrl() + "/api/repos/" + params[:id].to_s
        @repo = HTTParty.get(repo_url,
            headers: { 'Accept' => '*/*',
             'Content-Type' => 'application/json',
             'Authorization' => 'Bearer ' + token }).parsed_response
        if @repo.nil?
            redirect_to info_path(title: t('general.invalidAddress'), 
                text: t('general.inexistentOrDenied'))
            return
        else
          items_url = getServerUrl() + '/api/repos/id/' + params[:id].to_s + '/items'
          app = { "pia_url" => getServerUrl(),
                  "app_key" => nil,
                  "app_secret" => nil,
                  "token" => token }
          @items = readRawItems(app, items_url)
          @items = @items.sort_by{ |item| JSON.parse(item)["id"] rescue 0 }
          @items = @items.paginate(page: params[:page], :per_page => 200)
        end
    end

    def show
      token = session[:token]
      item_url = getServerUrl() + "/api/items/" + params[:item_id].to_s + "/details"
      @item = HTTParty.get(item_url,
          headers: { 'Accept' => '*/*',
           'Content-Type' => 'application/json',
           'Authorization' => 'Bearer ' + token }).parsed_response
      if @item.nil? | @item.key?("error")
          redirect_to info_path(title: t('general.invalidAddress'), 
              text: t('general.inexistentOrDenied'))
          return
      else
        if @item['repo_id'].to_s == params[:repo_id].to_s
          @encrypted = false
          if !@item['value'].nil? && !JSON.parse(@item['value'])['nonce'].nil?
            @encrypted = true
          end
          @valid_hash = (Digest::SHA256.digest(@item['value']).unpack('H*')[0].to_s == @item['oyd_hash'].to_s)

          @transaction_address = ""
          @valid_roothash = false
          @valid_transaction = false
          @timestamp = nil
          if @item['merkle_id'].to_s != ""
              merkle = Merkle.find(@item['merkle_id'])
              payload = JSON.parse(merkle.payload)
              transaction = merkle.oyd_transaction
              mht = Marshal::load(Base64.decode64(merkle.merkle_tree.delete("\n")))
              pos = payload.index(@item['id'])
              leaf = Digest::SHA256.digest("\0" + Digest::SHA256.digest(@item['value']))
              @valid_roothash = ((mht.send(:leaf_hash, pos) == leaf) &&
               (mht.head.unpack('H*')[0] == merkle.root_hash))
              @audit_proof = mht.audit_proof(pos).collect {|item| item.unpack('H*')[0] }.join(', ')

              # i = 0
              # h1 = Digest::SHA256.digest("\0" + Digest::SHA256.digest(@item['value']))
              # begin
              #   h2 = mht.audit_proof(pos)[i]
              #   # take care to take left/right node in tree
              #   if ???
              #     h1 = mht.send :node_hash, h1, h2
              #   else
              #     h1 = mht.send :node_hash, h2, h1
              #   i = i+1
              # end while i < mht.audit_proof(pos).length
              # valid = (mht.head == mht.send(:node_hash, h1, h2))

              blockchain_url = 'http://' + ENV["DOCKER_LINK_BC"].to_s + ':3010/getTransactionStatus'
              response = HTTParty.get(blockchain_url,
                headers: { 'Content-Type' => 'application/json'},
                body: { id:   merkle.id, 
                        hash: transaction }.to_json ).parsed_response
              if !response["transaction-status"].nil?
                transaction_check = response["transaction-status"]["transactionHash"]
                @valid_transaction = (transaction_check == transaction)
                @transaction_address = transaction
                @transaction_address[0..1] = ''

                blockTimestamp = response["transaction-status"]["blockTimestamp"]
                @bcts = Time.at(blockTimestamp.to_i(16)).strftime('%Y-%m-%dT%H:%M:%SZ')
              end
          end
          if !@item['oyd_source_pile_id'].nil?
            source_pile_url = getServerUrl() + "/api/piles/" + @item['oyd_source_pile_id'].to_s 
            retVal = HTTParty.get(source_pile_url,
                                  headers: { 'Accept' => '*/*',
                                   'Content-Type' => 'application/json',
                                   'Authorization' => 'Bearer ' + token }).parsed_response rescue ""
            if retVal == ""
              @item_source_pile_content = ""
              @item_source_pile_signature = ""
              @item_source_pile_verification = ""
            else
              @item_source_pile_content = JSON.parse(retVal["content"]).to_json
              @item_source_pile_signature = retVal["signature"]
              @item_source_pile_verification = retVal["verification"]
            end
          end
        else
          redirect_to info_path(title: t('general.invalidAddress'), 
              text: t('general.inexistentOrDenied'))
          return
        end
      end
    end

    def decrypt
        private_key = getReadKey(params[:password].to_s, session[:token].to_s)
        @decrypted_value = decrypt_message(params[:value].to_s, private_key)
        @invalidPwd = false
        if @decrypted_value.nil?
            @invalidPwd = true
        end
        respond_to do |format|
            format.js
        end

    end

    def edit
    end

    def delete
      token = session[:token]
      item_delete_url = getServerUrl() + 
      '/api/repos/id/' + params[:repo_id].to_s + 
      '/items/' + params[:item_id].to_s
      retVal = HTTParty.delete(item_delete_url,
        headers: { 'Accept' => '*/*',
         'Content-Type' => 'application/json',
         'Authorization' => 'Bearer ' + token })
      if retVal.code == 200
        flash[:info] = t('data.success_message')
      else
         flash[:warning] = t('data.error_message') + ": " + 
         oyd_backend_translate(retVal.parsed_response['error'].to_s, params[:locale])
      end

      redirect_to show_data_path(id: params[:repo_id])
    end

    def repo_delete
        token = session[:token]
        repo_delete_url = getServerUrl() + '/api/repos/' + params[:id].to_s
        retVal = HTTParty.delete(repo_delete_url,
            headers: { 'Accept' => '*/*',
             'Content-Type' => 'application/json',
             'Authorization' => 'Bearer ' + token })
        if retVal.code == 200
            flash[:info] = t('data.success_message')
        else
          flash[:warning] = t('data.error_message') + ": " + 
          oyd_backend_translate(retVal.parsed_response['error'].to_s, params[:locale])
      end
      redirect_to data_path
    end
end