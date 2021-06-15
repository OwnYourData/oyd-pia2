module Api
    module V1
        class RelationsController < ApiController
            # respond only to JSON requests
            respond_to :json
            respond_to :html, only: []
            respond_to :xml, only: []

            def get_relation(id, ttl, mode)
                retVal = []
                if mode == "undirected" || mode =="downstream"
                    retVal += OydRelation.where(source_id: id).pluck(:target_id).uniq
                end
                if mode == "undirected" || mode =="upstream"
                    retVal += OydRelation.where(target_id: id).pluck(:source_id).uniq
                end
                if ttl > 0
                    retVal.each do |item|
                        retVal += get_relation(item, ttl-1, mode)
                    end
                end
                retVal << id.to_i
                retVal.uniq
            end

            def index
                if doorkeeper_token.nil?
                    render json: {"error": "invalid token"},
                           status: 403
                    return
                end
                if current_resource_owner.nil?
                    user_id = Doorkeeper::Application.where(
                        id: doorkeeper_token.application_id).first.owner_id
                else
                    user_id = current_resource_owner.id
                end

                id = params[:id]
                ttl = params[:ttl].to_i rescue 0
                mode = params[:mode] || "undirected"

                @item = Item.find(id) rescue nil
                if @item.nil?
                    render json: {"error": "invalid source_id"},
                           status: 404
                    return
                end
                if @item.repo.user_id != user_id
                    render json: {"error": "invalid source_id"},
                           status: 403
                    return
                end

                result = []
                items = get_relation(id, ttl, mode)
                items.uniq.each do |i|
                    ds = []
                    us = []
                    if mode == "undirected" || mode =="downstream"
                        ds = OydRelation.where(source_id: i).pluck(:target_id).uniq
                    end
                    if mode == "undirected" || mode =="upstream"
                        us = OydRelation.where(target_id: i).pluck(:source_id).uniq
                    end

                    retVal = { "id": i }.stringify_keys
                    if ds.length > 0
                        retVal["downstream"] = ds
                    end
                    if us.length > 0
                        retVal["upstream"] = us
                    end
                    if ds.length > 0 || us.length > 0
                        result << retVal
                    end
                end
                render json: result,
                       status: 200
            end

            def create
                if doorkeeper_token.nil?
                    render json: {"error": "invalid token"},
                           status: 403
                    return
                end
                if current_resource_owner.nil?
                    user_id = Doorkeeper::Application.where(
                        id: doorkeeper_token.application_id).first.owner_id
                else
                    user_id = current_resource_owner.id
                end

                mode = params[:p].to_s rescue "id"
                if mode == ""
                    mode = "id"
                end
                sid = params[:source].to_s rescue ""
                tid = JSON.parse(params[:targets].to_json) rescue ""

                case mode
                when "id"
                    @item = Item.find(sid.to_i) rescue nil
                    if @item.nil?
                        render json: {"error": "invalid source id"},
                               status: 404
                        return
                    end
                    if @item.repo.user_id != user_id
                        render json: {"error": "invalid source id"},
                               status: 403
                        return
                    end

                    if tid.is_a? Array 
                        tid.each do |i|
                            @item = Item.find(i) rescue nil
                            if @item.nil?
                                render json: {"error": "invalid target_ids"},
                                       status: 404
                                return
                            end
                            if @item.repo.user_id != user_id
                                render json: {"error": "invalid target_ids"},
                                       status: 403
                                return
                            end
                        end
                    elsif tid.is_a? Integer
                        @item = Item.find(tid) rescue nil
                        if @item.nil?
                            render json: {"error": "invalid target_ids"},
                                   status: 404
                            return
                        end
                        if @item.repo.user_id != user_id
                            render json: {"error": "invalid target_ids"},
                                   status: 403
                            return
                        end
                    else
                        render json: {"error": "invalid target_ids"},
                               status: 400
                        return
                    end

                    if tid.is_a? Array 
                        tid.each do |i|
                            OydRelation.new(
                                source_id: sid,
                                target_id: i).save
                        end
                    else
                        OydRelation.new(
                            source_id: sid,
                            target_id: tid).save
                    end

                when "dri"
                    repos = Repo.where(user_id: user_id).pluck(:id)
                    @item = Item.where(dri: sid.to_s, repo_id: repos).first rescue nil
                    if @item.nil?
                        render json: {"error": "invalid source dri"},
                               status: 404
                        return
                    end
                    if @item.repo.user_id != user_id
                        render json: {"error": "invalid source dri"},
                               status: 403
                        return
                    end
                    sid = @item.id

                    tid_ids = []
                    if tid.is_a? Array 
                        tid.each do |i|
                            @item = Item.where(dri: i.to_s, repo_id: repos).first rescue nil
                            if @item.nil?
                                render json: {"error": "invalid target dris"},
                                       status: 404
                                return
                            end
                            if @item.repo.user_id != user_id
                                render json: {"error": "invalid target dris"},
                                       status: 403
                                return
                            end
                            tid_ids << @item.id
                        end
                    elsif tid.is_a? String
                        @item = Item.where(dri: tid.to_s, repo_id: repos).first rescue nil
                        if @item.nil?
                            render json: {"error": "invalid target dris"},
                                   status: 404
                            return
                        end
                        if @item.repo.user_id != user_id
                            render json: {"error": "invalid target dris"},
                                   status: 403
                            return
                        end
                        tid_ids << @item.id
                    else
                        render json: {"error": "invalid target dris"},
                               status: 400
                        return
                    end

                    tid_ids.each do |i|
                        OydRelation.new(
                            source_id: sid,
                            target_id: i).save
                    end

                else
                    render json: {"error": "unknown p (use 'id' or 'dri')"},
                           status: 403
                    return
                end

                render plain: "",
                       status: 200
            end
        end
    end
end