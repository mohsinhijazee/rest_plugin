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

# Add any attributes that should not be part of the representation here
to_be_skipped = [
                  'id'
                ]

xml.resource(:type => 'account_type') do
  # The URL of the resource
  xml.url url(account_type_url(account_type))
  
  # List all the attributes
  account_type.attributes.each do |attr, value|
    next if to_be_skipped.include? attr
    xml.tag!(attr.to_sym, value)
  end
  
  # Add any other URLs here.

end