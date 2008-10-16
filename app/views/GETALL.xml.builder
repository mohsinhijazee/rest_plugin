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

xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"

xml.resource_parcel do
  xml.total_resources @parcel[:total_resources]  
  xml.resources_returned  @parcel[:resources_returned] 
  xml.start_index @parcel[:start_index]
  xml.order_by @parcel[:start_index]
  xml.direction @parcel[:direction]
  xml.conditions @parcel[:conditions]
  resources = render( :partial => @parcel[:resource_type] + '.xml.builder', 
                      :collection => @parcel[:resources])

  xml.resources(:type => 'array') do
    xml << resources
  end

# Approach two
#  xml.resources(:type => 'array') do
#    #xml << resources
#    @parcel[:resources].each do |resource| 
#      xml.resource do
#        xml << render(:partial => @parcel[:resource_type] + '.xml.builder', :locals => {:resource => resource})
#      end
#    end
#  end
  
end
