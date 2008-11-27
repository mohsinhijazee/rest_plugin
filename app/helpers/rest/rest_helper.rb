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

module Rest::RestHelper
  # *Description*
  #   This method takes a URL and adds extention of the same format as that of 
  #   request. For example, if the request was like this:
  #   GET /databases.json
  #   Then all the URLs in the response would endup with .json extention
  def url(url)
    return url if params[:format].nil?
    return url if url =~ /\.\w+$/
    return "#{url}.#{params[:format]}" 
  end
  
  # *Description*
#  This method takes a hash which describes a detail valu.e
# if the datatype is the one which holds files, then value is replaced with URL
# instead of the YAML. This is a workaround and it should not be this way.
# get_records_for should populate value items with proper class objects instead
# of hashes. This will eliminate this approach where we have to list every external 
# datatype.
def process_value(item)
  attachment_types = ['madb_swf_attachment', 
                      'madb_file_attachment', 
                      'madb_s3_attachment']
                    
 if attachment_types.include? item[:data_type]
   download_url = "#{request.protocol}#{request.host}#{request.port_string}/app/file_attachments/download/#{item[:id]}"
   
   file_props = YAML::load item[:value]
   file_props[:download_url] = download_url
   item[:value] = file_props
 end
   return item[:value]
end


end