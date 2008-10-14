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

# 
# *Description*
#   Proivdes the REST Interface to the links resources
#   
#   01- GET       instance/:instance_id/links
#   02- GET       /links/:id
#   03- POST      /links
#   04- DELETE    /links/:id
#

require 'json'

class Rest::LinksController < ApplicationController
  include Rest::RestValidations
  include Rest::UrlGenerator
  include InstanceProcessor
  
  before_filter :login_required
  
  before_filter :validate_rest_call
  
  before_filter :check_ids
  
  before_filter :check_relationships
  
  # NOT NEEDED!
  #before_filter :check_relationships
  
  # NOT NEEDED!
  #before_filter :adjust_params
  
  def index
    begin

      conditions = "(parent_id=#{params[:instance_id]} or child_id=#{params[:instance_id]})"
      params[:conditions] = add_condition(params[:conditions], conditions, :and) 
      
      results = get_paginated_records_for(
      :for            => Link,
      :start_index    => params[:start_index],
      :max_results    => params[:max_results],
      :order_by       => params[:order_by],
      :direction      => params[:direction],
      :conditions     => params[:conditions]
      )
    rescue Exception => e
      render :text => report_errors(nil, e)[0], :status => 500 and return
    end
    
    respond_to do |format|
      format.json { render :json => results.to_json(:format => 'json') and return }
    end
  end
  
  def show
    @links = Link.find(params[:id])
    
    respond_to do |format|
      format.json {render :json => @links.to_json(:format => 'json') and return }
    end
  end
  
  def create
    @link = Link.new(params[:link])
    puts @link.relation_id
    puts @link.child_id
    puts @link.parent_id
    
    begin
      @link.save!
      @msg = 'OK'
      @code = 201
    rescue Exception => e
      @msg, @code = report_errors(@link, e)
    end
    
    #@msg = 'TEST'
    #@code = 908
    
    respond_to do |format|
      format.json do 
        @msg = [(@@lookup[:Link] % [@@base_url, @link.id]) + '.json'] if @code == 201
        render :json => @msg, :status => @code and return 
      end
    end
      
    
    
  end
  
  def update
    render :json => report_errors(nil,  "Action '#{params[:action]}' not allowed on links")[0], :status => 400
  end
  
  def destroy
    @link = Link.find(params[:id])
    begin
      @link.destroy
      @msg = 'OK'
      @code = 200
    rescue Exception => e
      @msg = report_errors(nil, e)[0]
      @code = 500
    end
    
    respond_to do |format|
      format.json { render :json => @msg, :status => @code}
    end
    
  end
  

  
 
  protected
  
  def validate_rest_call
    
    # Parse the JSON and if invalid, return false
    if params[:link]
      begin
        params[:link] = JSON.parse(params[:link])
        params[:link] = substitute_ids(params[:link])
        check_id_conflict(params[:link], params[:id])
        valid_link?(params[:link], params)
      rescue MadbException => e
        render :json => report_errors(nil, e)[0], :status => e.code and return false
      rescue Exception => e
        respond_to do |format|
          format.json { render :json => report_errors(nil, e)[0], :status => 400 and return false}
        end
      end
    end
      
    
    if params[:action] == 'index'
      render :json => report_errors(nil, 'GET /links not allowed, Use GET instances/:instance_id/links instead')[0],
        :status => 400 and return false if !params[:instance_id]
    end
    
    if params[:action] == 'create' or params[:action] == 'update'
      render :json => report_errors(nil, 'Provide the link paramter to be created/updated')[0],
        :status => 400 and return false if !params[:link]
      #@json_in = params[:link]
      
#      # The consumer of the API may skip either the child id or parent id and 
#      # if will be picked from instance id
#      if params[:instance_id] and !params[:link][:parent_id] and params[:link][:child_id]
#        params[:link][:parent_id] = params[:instance_id]
#      end
#      
#      if params[:instance_id] and !params[:link][:child_id] and params[:link][:parent_id]
#        params[:link][:child_id] = params[:instance_id]
#      end
#      
#      
    end
    
    
    # In all other cases, its ok
    return true;
  end
  
  def check_ids
    if params[:id]
      render :json => report_errors(nil, "Link[#{params[:id]}] does not exists")[0], 
        :status => 404 and return false if !Link.exists?(params[:id].to_i)
    end
    
    if params[:instance_id]
      render :json => report_errors(nil, "Instance[#{params[:instance_id]}] does not exists")[0], 
        :status => 404 and return false if !Instance.exists?(params[:instance_id].to_i)
    end
    
    # In all other cases, its ok
    return true;
    
  end
  
  def check_relationships
    
    if params[:instance_id] and params[:id]
      render :json => report_errors(nil, "Link[#{params[:id]}] does not belong to Instance[#{params[:instance_id]}]")[0],
        :status => 400 and return false if !related_to_each_other?(
                                            :instance => params[:instance_id],
                                            :link => params[:id])
    end
    
    begin
      belongs_to_user?(session['user'], 
                    :instance => params[:instance_id],
                    :link => params[:id])
    rescue MadbException => e
      render :json => report_errors(nil, e)[0], :status => 400 and return false
    end
  end
  
   protected
 # Overriden from LoginSystem in order to render custom message
  def access_denied
    render :json => %Q~{"errors": ["Please login to consume the REST API"]}~, :status => 401
  end 
  
end
