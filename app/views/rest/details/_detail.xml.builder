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
#   This templae renders a sinlge resource and it is always rendered as partial.
#   It is called by following views:
#     * GET.xml.builder
#     * GETALL.xml.builder
#     * PUT.xml.builder
#     
#   == Conventions
#     * The resource being rendered is always available as a local variable to
#       this template of same name as of this template. For example, if the 
#       template name is _relation_type.xml.builder then the resource to be
#       rendered will be available as relation_type.
#       
#     * At the very outset, URL of the resource is rendered
#     
#     * Next, all the attributes of the resource are rendered.
#     
#     * Lastly, any addtional URLs are added to it.
#     
#     * Any attributes that should not be rendered are listed in the array naemed
#       'to_be_skipped'
#     

# Add any attributes that should not be part of the representation here
to_be_skipped = [
                  :id,
                  :database_id,
                  :data_type_id,
                  :status_id
                ]


# Add all the URLs to this model
hash = detail.attributes.symbolize_keys

hash[:url]             = url(detail_url(detail))
hash[:database_url]    = url(database_url(:id => detail.database_id))
hash[:data_type_url]   = url(data_type_url(:id => detail.data_type_id))
hash[:status_url]      = url(detail_status_url(:id => detail.status_id)) if detail.status_id

if detail.data_type.name == 'madb_choose_in_list'
  hash[:propositions_url]  = url(detail_propositions_url(:detail_id => detail.id))
end


# Remove any keys
to_be_skipped.each {|attr| hash.delete attr} 

hash.to_xml  :builder        => xml,
             :root           => 'detail', 
             :dasherize      => false, 
             :skip_instruct  => true

# OLD APPROACH
###########################
#xml.detail do
#  # The URL of the resource
#  
#  
#  
#  xml.url url(detail_url(detail))
#  
#  # List all the attributes
#  detail.attributes.each do |attr, value|
#    next if to_be_skipped.include? attr
#    #xml.tag!(attr.to_sym, value, :type => 'string')
#    typed_tag xml,  attr, value
#  end
#  
#  # Add any other URLs here.
#  xml.database_url      url(database_url(:id => detail.database_id))
#  xml.data_type_url     url(data_type_url(:id => detail.data_type_id))
#  xml.status_url        url(detail_status_url(:id => detail.status_id)) if detail.status_id
#  
#  # URL for propositions if applicable
#  if detail.data_type.name == 'madb_choose_in_list'
#    xml.propositions_url  url(detail_propositions_url(:detail_id => detail.id))
#  end
#  
#end