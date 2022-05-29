module PlantumlHelper
    def plantuml(provision)
puts "in PlantumlHelper"
        begin
            @item = Item.find(provision["id"])
puts "ID: " + @item.id.to_s

            retVal = @item.provenance
puts "Provision: ---------"
puts retVal.to_s


            if retVal.to_s.strip == ""
                retVal = "@startuml\nobject Response\nResponse : Provenance cannot be displayed\n@enduml"
            end    
        rescue
            retVal = "@startuml\nobject Response\nResponse : Provenance cannot be displayed\n@enduml"
        end
puts "Return: ---------"
puts retVal.to_s

        return retVal
    end
end