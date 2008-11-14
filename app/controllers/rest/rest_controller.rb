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

#TODO: All the validate_rest_calls should happpend here
#TODO: Errors should be based on exceptions which should be properly reported back
#TODO: REST authentication

class Rest::RestController < ActionController::Base
  include Rest::RestValidations
  include InstanceProcessor
  include Rest::UrlGenerator
  
  # We neet to replace with REST authentication. For now, its cookie based.
  # No authentication required for now
  before_filter :login_required
  
  #before_filter :log_me_in
  #after_filter :log_me_out

  # *Description*
  #  Logs mohsinhijazee@zeropoint.it to the session
  #  This method is needed only as a development tool because we're moving towards
  #  pure REST philosophy so will not be supplying cookies with our reqeusts sometimes.
  #  So for those times, it should fall back to some user.
  def log_me_in
    puts headers
    session['user'] = User.find(:first, :conditions => ["login='mohsinhijazee@zeropoint.it'"])
  end
  
  # *Description*
  #  Clears the session
  def log_me_out
    session['user'] = nil
  end
  
  # *Description*
  #   Custome render method that allows us to render content into JSON and YAML 
  #   formats.
  # This method also allows you to render specific REST responses. 
  # 
  # * For rendering GET, PUT, POST:
  #   You must set @resource instance variable.
  # * For rendering GETALL:
  #   @parcel instance variable must contain resource parcel
  # * For rendering error, @error must contain an exception object returned
  #   by process_exception method
  #   
  # == Exmaple:
  #   @parcel = get_paginated_resutls()
  #   render :response => GETALL
  #   
  #   Another example:
  #     begin
  #       @resource = Database.find 1
  #       render :response => GET
  #     rescue Exception => e
  #       @error = process_exception(e)
  #       render :response => :error
  #     end
  # You can supply response type to be rened as string also and they are case
  # insensitive.
  #  
  def render(opts = {}, &block)
   
    opts[:status] = 200 if !opts[:status]
    if opts[:to_yaml] then
      headers["Content-Type"] = "text/plain;"
      yaml = Hash.from_xml(render_to_string(:template => opts[:to_yaml], :layout => false)).to_yaml
      render :text => yaml, :layout => false, :status => opts[:status]
    elsif opts[:to_json] then
      content = Hash.from_xml(render_to_string(:template => opts[:to_json], :layout => false)).to_json
      cbparam = params[:callback] || params[:jsonp]
      content = "#{cbparam}(#{content})" unless cbparam.blank?
      render :json => content, :layout => false, :status => opts[:status]
    elsif opts[:to_xml]
      content = render_to_string(:template => opts[:to_xml], :layout => false)
      headers["Content-Type"] = "application/xml;"
      render :text => content, :layout => false, :status => opts[:status]
    elsif opts[:response]
      render_rest_response opts[:response]
    else
      super opts, &block
    end
end

  # *Description*
  #   Renders different REST responses.
  def render_rest_response(opts)
    if opts.to_s.downcase == 'getall'
      render_get_all
    elsif opts.to_s.downcase == 'get'
      render_get
    elsif opts.to_s.downcase == 'post'
      render_post
    elsif opts.to_s.downcase == 'put'
      render_put
    elsif opts.to_s.downcase == 'delete'
      render_delete
    elsif opts.to_s.downcase == 'error'
      render_error
    end
  end

  
  # *Description*
  #   Renders a standad GET response to a GET call based on the request format.
  #   Renders views/GET.xml.builder internally
  #
  def render_get
      respond_to do |wants|
        wants.html {render :to_xml  => 'GET.xml.builder', :layout => false}
        wants.xml  {render :to_xml  => 'GET.xml.builder', :layout => false}
        wants.json {render :to_json => 'GET.xml.builder'}
        wants.yaml {render :to_yaml => 'GET.xml.builder'}
      end
      
  end
  
  # *Description*
  #   Renders a standad GET response to a GET call based on the request format.
  #   Renders views/GETALL.xml.builder internally
  #
  def render_get_all
    respond_to do |wants| 
        wants.html {render :to_xml  => 'GETALL.xml.builder', :layout => false}
        wants.json {render :to_json => 'GETALL.xml.builder'}
        wants.xml  {render :to_xml  => 'GETALL.xml.builder', :layout => false}
        wants.yaml {render :to_yaml => 'GETALL.xml.builder'}
      end    
  end
  
  # *Description*
  #   Renders a standad POST response to a POST call based on the request format.
  #   Renders views/POST.xml.builder internally
  #
  def render_post
      respond_to do |wants| 
        wants.html {render :to_xml  => 'POST.xml.builder', :layout => false, :status => 201}
        wants.json {render :to_json => 'POST.xml.builder', :status => 201}
        wants.xml  {render :to_xml  => 'POST.xml.builder', :layout => false, :status => 201}
        wants.yaml {render :to_yaml => 'POST.xml.builder', :status => 201}
      end          
  end  
  
  # *Description*
  #   Renders a standad PUT response to a PUT call based on the request format.
  #   Renders views/PUT.xml.builder internally
  #
  def render_put
    respond_to do |wants| 
      wants.html {render :to_xml  => 'PUT.xml.builder', :layout => false, :status => 200}
      wants.json {render :to_json => 'PUT.xml.builder', :status => 200}
      wants.xml  {render :to_xml  => 'PUT.xml.builder', :layout => false, :status => 200}
      wants.yaml {render :to_yaml => 'PUT.xml.builder', :status => 200}
    end            
  end
 
  # *Description*
  #   Renders a standad DELETE response to a DELETE call based on the request format.
  #   Renders views/DELETE.xml.builder internally
  #
  def render_delete
     respond_to do |wants| 
        wants.html {render :to_xml  => 'DELETE.xml.builder', :layout => false, :status => 200}
        wants.json {render :to_json => 'DELETE.xml.builder', :status => 200}
        wants.xml  {render :to_xml  => 'DELETE.xml.builder', :layout => false, :status => 200}
        wants.yaml {render :to_yaml => 'DELETE.xml.builder', :status => 200}
      end
  end
  
  # *Description*
  #   Renders a standad error message
  #   Renders views/error.xml.builder internally
  #
  def render_error
    respond_to do| wants|
        wants.html {render :to_xml  => 'error.xml.builder', :layout => false, :status => @error.code }
        wants.json {render :to_json => 'error.xml.builder', :status => @error.code }
        wants.xml  {render :to_xml  => 'error.xml.builder', :layout => false, :status => @error.code }
        wants.yaml {render :to_yaml => 'error.xml.builder', :status => @error.code }
      end
  end
  
  
end