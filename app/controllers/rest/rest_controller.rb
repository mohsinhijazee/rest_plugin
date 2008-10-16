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
#   This is the base controller for controllers that provide REST services.
# It would handle the validation and authentication of the REST calls.


class Rest::RestController < ApplicationController
  include Rest::RestValidations
  include InstanceProcessor
  include Rest::UrlGenerator
  
  # We neet to replace with REST authentication. For now, its cookie based.
  # No authentication required for now
  #before_filter :login_required

  # *Description*
  #   Custome render method that allows us to render content into JSON and YAML 
  # formats.
  def render(opts = {}, &block)
  if opts[:to_yaml] then
    headers["Content-Type"] = "text/plain;"
    render :text => Hash.from_xml(render_to_string(:template => opts[:to_yaml], :layout => false)).to_yaml, :layout => false
  elsif opts[:to_json] then
    content = Hash.from_xml(render_to_string(:template => opts[:to_json], :layout => false)).to_json
    cbparam = params[:callback] || params[:jsonp]
    content = "#{cbparam}(#{content})" unless cbparam.blank?
    render :json => content, :layout => false
  elsif opts[:to_xml]
    content = render_to_string(:template => opts[:to_xml], :layout => false)
    headers["Content-Type"] = "application/xml;"
    render :text => content, :layout => false
  else
    super opts, &block
  end
end

  
end