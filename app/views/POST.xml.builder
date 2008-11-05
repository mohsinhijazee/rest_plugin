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

#either a single resource
# or is array
  #array is either of instances, or of detail values.
  
# If any other thing other then detail values or instances then:
if @resource.is_a? ActiveRecord::Base
  url_for = "#{@resource.class.name.underscore}_url".to_sym
  url =  url(self.send( url_for, @resource))
  xml.url url
else
  # But if these are instances or detail values, then we will return
  # an array of URLs.
  xml.url(:type => 'array') do
    # For each of item, generate a URL based on its type. Note that collection
    # either be totally of instances or totally of detail value and its subclasses
    @resource.each do |item|
      if item.is_a? DetailValue
        url = instance_detail_value_url(:instance_id  => item.instance_id,
                                        :detail_id    => item.detail_id,
                                        :id           => item.id)
      else
        resource_type = item.class.name.underscore
        resource_type = 'proposition' if item.class == DetailValueProposition
        url = url(self.send("#{resource_type}_url".to_sym, item))
      end
      xml.url url(url)
    end
  end
end