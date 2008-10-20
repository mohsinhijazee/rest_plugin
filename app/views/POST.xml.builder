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
#  This template renders the response to the REST consumer if the creation of the
#  resource is succussfull. All it does is returning the URL of the newly created
#  resource.
#  
#  == Conventions
#    * The newly created resoruce is always recieved in @resource instance 
#      variable. 
#    * Only the URL of the newly created resource is returned.
#
#
xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
# Here is how we generate the URL for the newly created resource. Suppose we
# created a new RelationType. To get the URL of the newly created RelationType
# resource, we need to call relation_type_url(@resource).
# But we cant hard type here! Because this template is being shared by many.
# So for that, we get the class name of the newly created resoruce by:
# @resource.class.name
#  And then turn it to underscore by undersore method which comes from ActiveSupport
# @resource.class.name.underscore
# And then append _url to it and the convert it to symbol:
# url_for = "#{@resource.class.name.underscore}_url".to_sym
# Next we send call to method of this name to the current class by:
# self.send(url_for, @resource) 
# This is same as => ActionView::Base.account_type_url(@resource)
# Next we call url method of the Rest::RestController helper module which appends
# extention of the format being requested.
#
url_for = "#{@resource.class.name.underscore}_url".to_sym
xml.url url(self.send url_for, @resource)
