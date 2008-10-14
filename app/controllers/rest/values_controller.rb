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
#   This provides the value as a resoruce through REST.
#   
#   01- GET /instances/:instance_id/details/:detail_id/values
#
#
# For creating values, you need to put following minial resource to the controller:
# {value: [val1, val2, val3]}
#          OR
# {value: value}
# 
# For update, you also need to dispatch your updates in value parameter with follwoing
# {value: value}
# # Note that for updates, you can only dispatch single value. If you do and update like this:
# {value: [val1, val2, val3]}
# Then only val1 will be considered and rest will be ignored.
#

require 'json'
class Rest::ValuesController < ApplicationController
  include InstanceProcessor
  include Rest::RestValidations
  include Rest::UrlGenerator
  
  before_filter :login_required
  
  before_filter :validate_rest_call
  
  before_filter :check_ids
  
  before_filter :check_relationships
  
  # NOT Needed!
  #before_filter :adjust_params
  
  def index
    #NOTE! WE DO NOT IMPLEMENT PAGINATION FOR VALUES ON PURPOSE!
    #values = get_all_values(params[:instance_id], params[:detail_id])
    begin
      condition = "(instance_id=#{params[:instance_id]} AND detail_id=#{params[:detail_id]})"
      params[:conditions] = add_condition(params[:conditions], condition, :and)
      
      values = get_paginated_records_for(
      :for            => DetailValue,
      :instance_id    => params[:instance_id],
      :detail_id      => params[:detail_id],
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
      format.json { render :json => values.to_json(:format => 'json') and return if values}
    end
    
    # If control reaches here, it means no value was found!
    render :json => "No values found for Detail[#{params[:detail_id]}] of Instance[#{params[:instance_id]}]",
      :status => 200 and return
  end
  
  def show
    begin
      value = get_single_value(params[:detail_id], params[:id])
    rescue Exception => e
      render :json => report_errors(nil, e)[0], :status => 500 and return
    end
    
    respond_to do |format|
      format.json { render :json => value.to_json(:format => 'json') and return}
    end
    
  end
  
  def create
    values = []
    urls = []
    begin
      DetailValue.transaction do
        values = save_all_values(params[:instance_id], params[:detail_id], params[:value][:value])
      end
    rescue Exception => e
      respond_to do |format|
        format.json { render :json => report_errors(nil, e)[0], :status => 400 and return }
      end
    end
    
    
    values.each do |value|
      urls.push((@@lookup[:DetailValue] % [@@base_url, value.instance_id, value.detail_id, value.id]) + '.json')
    end
    
    respond_to do |format|
      format.json { render :json => urls.to_json, :status => 201}
    end
    
  end
  
  #NOTE: This method returns nil in an array
  # Updating a value increments the instance number also!
  def update
    value = nil
    begin
      DetailValue.transaction do
        # Increment the instance version
        increment_instance_version
        value = update_value(params[:detail_id], 
                            params[:id], 
                            {
                              'lock_version' => params[:value][:lock_version],
                              'value' => params[:value][:value]                              
                            })
        @msg = value.to_json(:format => 'json') if value
        @msg = '[null]' if !value
        @code = 200
      end
    rescue ActiveRecord::StaleObjectError => e
      @msg = report_errors(nil, e)[0]
      @code = 409
    rescue MadbException => e
      @msg = report_errors(nil, e)[0]
      @code = e.code
    rescue Exception => e
      puts e.backtrace
      @msg = report_errors(nil, e)[0]
      @code = 500
      
    end
    
    
    respond_to do |format|
      format.json { render :json => @msg, :status => @code and return }
    end
    
  end
  
  def destroy
    begin
      destroy_value(params[:detail_id], params[:id], params[:lock_version])
      @msg = 'OK'
      @code = 200
    
    rescue ActiveRecord::StaleObjectError => e
      @msg = report_errors(nil, e)[0]
      @code = 409      
    rescue Exception => e
      @msg = report_errors(nil, e)[0]
      @code = 500
    end
    

    respond_to do |format|
      format.json { render :json => @msg, :status => @code and return }
    end
    
  end
  
  protected
  
#  # *Description*
#  #   This function gets all the values against a detail of an instance.
#  #   
#  # *Workflow*
#  #   The detail of the given id is picked and a condition is prepared
#  #   with having instance id to be the provided id of the instance and detail
#  #   id to be the id of the detail.
#  #   The appropiate data type class is retireved by the function
#  #   +class_from_name+() and a find call is executed ont that
#  #
#  #
#  def get_all_values(instance_id, detail_id)
#    # Initially, no values!
#    values = nil
#    # Get the detail of the given id
#    detail = Detail.find(detail_id)
#    # So these are the conditions for getting the values
#    condition = ["instance_id = ? AND detail_id = ?", instance_id, detail_id]
#    
#    # Get the class of the data type of the detail and execute a find on it
#    values = class_from_name(detail.data_type.class_name).find(:all, :conditions => condition)
#      
#    return values
#  end
#  
  
  
  def validate_rest_call
    
#    render :text => report_errors(nil,
#      'Only /instances/details/values is allowed')[0], 
#      :status => 400  and return false if !params[:instance_id] or !params[:detail_id]
    
    #if its call for creation and updation, the json must be provieded representing
    # the values to be created/updated in params[:value]
    
      
    if params[:value]
      begin
          params[:value] = JSON.parse(params[:value])
          params[:value] = substitute_ids(params[:value])
          check_id_conflict(params[:value], params[:id])
          valid_detail_value?(params[:value], params)
      rescue MadbException => e
        render :json => report_errors(nil, e)[0], :status => e.code and return false
      rescue Exception => e
        respond_to do |format|
          format.json {render :json => report_errors(nil, e)[0], :status => 400 and return false}
        end
      end
    end
    
    if params[:action] == 'create'
      render :json => report_errors(nil, 'Provide the JSON of the values to be created/updated in values parameter')[0],
        :status => 400 and return false if !params[:value]
      
      render :json => report_errors(nil, 'Only POST /instances/details/values is allowed')[0],
        :status => 400 and return false if !params[:instance_id] and !params[:detail_id]
    end
    
    
    if params[:action] == 'update'
      render :json => report_errors(nil, 'Provide the value to be updated in value parameter')[0],
        :status => 400 and return false if !params[:value]
    end
    
    if params[:action] == 'index'
      render :json => report_errors(nil, 'Only GET /instances/details/values is allowed')[0],
        :status => 400 and return false if !params[:instance_id] and !params[:detail_id]
    end
    
    if params[:action] == 'destroy'
      render :json => report_errors(nil, 'Provide lock_version for update/delete operations')[0],
        :status => 400 and return false if !params[:lock_version]
    end
    
    
    
    return true
  end
  
  def check_ids
    
    if params[:instance_id]
      render :json => report_errors(nil, "Instance[#{params[:instance_id]}] does not exists")[0], 
        :status => 404 and return false if !Instance.exists?(params[:instance_id].to_i)
    end
    
    if params[:detail_id]
      render :json => report_errors(nil, "Detail[#{params[:detail_id]}] does not exists")[0], 
        :status => 404 and return false if !Detail.exists?(params[:detail_id].to_i)
    end
    
    # If the id of the value is given, ensure that it exists
    if params[:id]
      # Get the class name of the value being mentioned through id.
      class_name = Detail.find(params[:detail_id]).data_type.class_name
      render :json => report_errors(nil, "#{class_name}[#{params[:id]}] does not exists")[0],
        :status => 404 and return false if !class_from_name(class_name).exists?(params[:id])
    end
    
    # In all other cases, its ok
    return true;
    
    
  end
  
  def check_relationships
    if params[:instance_id] and params[:detail_id] and params[:id]
      render :json => report_errors(nil,"Value[#{params[:id]}] does not belong to Detail[#{params[:detail_id]}] and Instance[#{params[:instance_id]}]")[0],
        :status => 400 and return false if !related_to_each_other?( :instance => params[:instance_id],
                                                                    :detail => params[:detail_id],
                                                                    :value => params[:id])
    end
    
    if params[:instance_id] and params[:detail_id]
      render :json => report_errors(nil,"Detail[#{params[:detail_id]}] does not belong to Instance[#{params[:instance_id]}]")[0],
        :status => 400 and return false if !related_to_each_other?(:instance => params[:instance_id],
                                                                  :detail => params[:detail_id])
    end
    
    begin
      belongs_to_user?(session['user'], 
        :instance => params[:instance_id],
        :detail => params[:detail_id],
        :value => params[:id]
                    )
    rescue MadbException => e
      render :json => report_errors(nil, e)[0], :status => 400 and return false
    end
    
    return true
  end
  
  protected
 # Overriden from LoginSystem in order to render custom message
  def access_denied
    render :json => %Q~{"errors": ["Please login to consume the REST API"]}~, :status => 401
  end
  
  private
  def increment_instance_version
    if params[:instance_id]
      Instance.find(params[:instance_id]).save!
    else
      value = class_from_name(Detail.find(params[:detail_id]).data_type.class_name).find(params[:id])
      Instance.find(value.instance_id).save!
    end
    
  end
  
  
  
end
