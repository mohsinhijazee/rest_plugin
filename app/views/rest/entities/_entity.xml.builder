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
                  :account_id
                ]
# Add all the URLs to this model
hash = entity.attributes

hash[:url]             = url(entity_url(entity))
hash[:details_url]     = url(entity_details_url(:entity_id => entity.id))
hash[:instances_url]   = url(entity_instances_url(:entity_id => entity.id))
hash[:relations_url]   = url(entity_relations_url(:entity_id => entity.id))

# Remove any keys
to_be_skipped.each {|attr| hash.delete attr} 

hash.to_xml  :builder        => xml,
             :root           => 'entity', 
             :dasherize      => false, 
             :skip_instruct  => true
           
#                
##FIXME: udner a resource tag? or account_type tag?
##resource tag adds an additional key of type to JSON
##xml.resource(:type => 'account_type') do
#xml.entity do
#  # The URL of the resource
#  xml.url url(entity_url(entity))
#  
#  # List all the attributes
#  entity.attributes.each do |attr, value|
#    next if to_be_skipped.include? attr
#    xml.tag!(attr.to_sym, value)
#  end
#  
#  # Add any other URLs here.
#  xml.details_url  url(entity_details_url(:entity_id => entity.id))
#  xml.instances_url url(entity_instances_url(:entity_id => entity.id))
#  xml.relations_url url(entity_relations_url(:entity_id => entity.id))
#
#end