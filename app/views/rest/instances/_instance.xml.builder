################################################################################
#This file is part of Dedomenon.
#
#Dedomenon is free software: you can redistribute it and/or modify
#it under the terms of the GNU Affero General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#Dedomenon is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU Affero General Public License for more details.
#
#You should have received a copy of the GNU Affero General Public License
#along with Dedomenon.  If not, see <http://www.gnu.org/licenses/>.
#
#Copyright 2008 Raphaël Bauduin
################################################################################

# *Description*
#   This template renders a single instance resource.
#   
#   
#

# Add any attributes that should not be part of the representation here
to_be_skipped = [
                  :id,
                  :entity_id,
                  :resource_type
                ]

value_attributes_to_skipped = [:id, :detail_id]

hash = instance.attributes
to_be_skipped.each {|attr| hash.delete attr}

# Add URLs
hash[:url] = url(instance_url(instance[:id]))
hash[:entity_url] = url(entity_url(:id => instance[:entity_id]))
hash[:details_url] = url(entity_details_url(:entity_id => instance[:entity_id]))
hash[:links_url] = url(instance_links_url(:instance_id => instance[:id]))


hash.each do |key, value|
  if value.is_a? Array
    value.each do |item|
      item[:url] = url(instance_detail_value_url(:instance_id => instance[:id], 
                                            :detail_id => item[:detail_id], :id => item[:id]))
      item[:detail_url] = url(detail_url(item[:detail_id]))
      value_attributes_to_skipped.each {|attr| item.delete attr}
    end
  end
end


hash.to_xml  :builder       => xml,
             :root          => 'instance',
             :dasherize     => false, 
             :skip_instruct => true

#xml.instance do
#  # The URL of the resource
#  xml.url url(instance_url(instance[:id]))
#  
#  #f = File.open('/home/mohsinhijazee/view_methods.txt', 'w+')
#  #f.write self.methods.join "\n"
#  #f.close
#  
#  # List all the attributes
#  instance.attributes.each do |col, values|
#    # If to be skipped, move on!
#    next if to_be_skipped.include? col.to_s
#    #puts self.methods
#    # If an array, then these are the values
#    if values.is_a? Array
#      # Create a tag of type array and of same name as column
#      xml.tag!(col, :type => 'array') do
#        # For each of the values
#        values.each do |value|
#          # Create a tag
#          xml.tag! col do
#            xml.url url(instance_detail_value_url(:instance_id => instance[:id], 
#                                            :detail_id => value[:detail_id], :id => value[:id]))
#            xml.detail_url url(detail_url(value[:detail_id]))
#            xml.value value[:value] 
#            xml.lock_version value[:lock_version]
#          end
#        end
#      end
#    else
#      xml.tag!(col, values)
#    end
#  end
#  
#  # Add any other URLs here.
#  xml.entity_url url(entity_url(:id => instance[:entity_id]))
#  xml.details_url url(entity_details_url(:entity_id => instance[:entity_id]))
#  xml.links_url url(instance_links_url(:instance_id => instance[:id]))
#  
#  #xml.values_url formatted_instance_detail_values_url(:instance_id => instance[:id], :detail_id => 12)
#  #xml.hash_for hash_for_entity_url(:id => instance[:entity_id])
#  
#  
#end
  
  
  

