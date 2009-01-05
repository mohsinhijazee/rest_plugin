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
#   This standard XML template renders all the GETALL calls. GETALL call is a 
#   simple GET request but it returns a collection of resources. All GETALL calls
#   in Dedomenon return a resource parcel which contains meta information about
#   the resource being returend like total number of resources, ordering information,
#   any conditions applied to them.
#   
#   == Conventions
#       * The resource parcel is always recieved in @parcel instance variable
#         from the index method of the controller.
#       * Meta information about parcel is rendered here.
#       * For the rest of the resources, appropiate xml builder from the views/rest
#         is called. Which view to call? This is indicated in @parcel[:resource_type]
#         and is set by the get_paginated_records method.
#       * After rendering the resutls placed under resources tag. This tag has
#         a 'type' attribute set to 'array' This would help conversion to JSON
#         as it will be converted into an array then.
#       
#       
#       
#
#

xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
# Render the appropiate resource template from views/rest
#resource_type = params[:controller][/\w+$/].singularize
resource_type = @parcel[:resource_type]
resources = render( :partial => resource_type + '.xml.builder', 
                    :collection => @parcel[:resources])

# Now delete the resources
@parcel.delete :resources

# Convert the parcel to XML via xml builder
@parcel.to_xml(:builder => xml,       :root => 'resource_parcel', 
                :dasherize => false,  :skip_instruct => true) do |xml_builder|
                
  xml_builder.resources(:type => 'array') do
    xml_builder << resources
  end
end
                
             
# Now place the resouces also!
#xml << resources
  

# Approach two
#  xml.resources(:type => 'array') do
#    #xml << resources
#    @parcel[:resources].each do |resource| 
#      xml.resource do
#        xml << render(:partial => @parcel[:resource_type] + '.xml.builder', :locals => {:resource => resource})
#      end
#    end
#  end
  

