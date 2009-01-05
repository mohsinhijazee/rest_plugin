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
#   This XML template represents a POST response. A POST response is identical
#   as a GET response for now.
#   We could have reused GET template but in order to accomodate any future
#   extentions, we've adopted it separately.
#   
#   == Conventions
#      Conventions are same as for GET template for now
#
xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"

#resource_type = params[:controller][/\w+$/].singularize
resource_type = @resource.class.name.underscore
resource_type = 'value'if @resource.is_a? DetailValue or [DateDetailValue, IntegerDetailValue].include? @resource.class
resource_type = 'proposition'if @resource.is_a? DetailValueProposition


resource_template = resource_type + '.xml.builder'
  resources = render(:partial => resource_template, 
                      :object => @resource)
xml << resources