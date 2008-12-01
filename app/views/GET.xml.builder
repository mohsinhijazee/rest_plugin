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

# *Descritpion*
#   This XML template renders all the GET REST calls. In order to full fill the
#   request, the partial template in the subdirectory of that type of resource 
#   is rendered. This is a highly DRY approach where we use single builder
#   for serving all the templates.
#   
#   == Conventions:
#     * The resources from the rendering controller is always recieved
#       in an instance variable @resource.
#     * The @resource is passed in :object key which appears to the rendering
#       template as a local variable of same name as the name of template is
#       (This is Rails convention that :object would appear as local variable
#       as name of template).
#       
#   == Example:
#     Suppose an Entity resource of id 5 is required. 
#        * The call would go to Rest::EntitiesController#show method.
#        * Rest::EntitiesController#show will find entity of id 5 and would store 
#          it in instance variable @resource.
#        * Rest::EntitiesController#show will render GET.xml.builder template
#          which is the file you're reading now.
#        * This template renders the template under views/rest/entities/_entity.xml.builder
#          and passes the @resource under the key of :object. Now by Rails 
#          convention, the @resource would appear to the partial template as a
#          local variable named after the file name of template i.e. entity
#        
# TODO: What else should be passed to partial template as locals?
# Nothing else, because all is available as resource
# Written by: Mohsin Hijazee

xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
resource_type = params[:controller][/\w+$/].singularize
#resource_type = @resource.class.name.underscore
#resource_type = 'value' if @resource.is_a? DetailValue
#resource_type = 'proposition' if @resource.is_a? DetailValueProposition
resource_template = resource_type + '.xml.builder'
resource = render(:partial => resource_template, 
                      :object => @resource)
xml << resource