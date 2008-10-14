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
#   This class provides the REST Interface to the entities resource
#   It is derived from the Admin::EntitiesController so that the functionality 
#   can be resued.
#   
#                           *REST_API_CHART*
#  
#   2- GET      /entities/:id
#   3- PUT      /entities/:id
#   4- DELETE   /entities/:id
#   5- POST     /entities
#   6- GET      /databases/:database_id/entities
#   7- GET      /databases/:database_id/entities/:id
#   8- PUT      /databases/:database_id/entities/:id
#   9- POST     /databases/:database_id/entities/
#  10- DELETE   /databases/:database_id/entities/:id
#  
#                          *REST_API_NOTES*
#                         
#  5- For call number five, the database in which the entity is to be created
#     must be mentioned either in entity[database_id] or as a database_id 
#     parameter.
#   
#   
# *Resource*
#   The entity resource has following form:
#  entity[name]
#  entity[:database_id] (optional)
class Rest::EntitiesController < Admin::EntitiesController
  
  include Rest::RestValidations
  include Rest::UrlGenerator
  include InstanceProcessor
  
  # Not needed. Provided by the parent controller
  #before_filter :login_required
  
  before_filter :validate_rest_call
  
  before_filter :check_ids
  
  before_filter :check_relationships
  
  # This is required to adjust the parameters.
  before_filter :adjust_params
  
  
  # *Description*
  #   Gets all the entities
  #   by:
  #   
  #   * GET /entities/
  #   * GET /databases/entities
  #
  def index
    begin
      params[:conditions] = add_condition(params[:conditions], 
                            "database_id=#{params[:database_id]}", :and)
                          
      results = get_paginated_records_for(
        :for => Entity,
        :star_index => params[:start_index], 
        :max_results => params[:max_results],
        :order_by => params[:order_by], 
        :direction => params[:direction], 
        :conditions => params[:conditions])
    rescue Exception => e
      render :json => report_errors(nil, e)[0], :status => 500
    end

     
    respond_to do |format|
      format.json { render :json => results.to_json(:format => 'json') and return}
    end
  end
  
  # *Description*
  #   Gets a particulalr entity
  #   GET /entities/:id
  #
  def show
    begin
      super
    rescue Exception => e
      @msg, @code = report_errors(@entity, e)
      render :json => @msg, :status => @code and return
    end
    
    respond_to do |format|
      format.json { render :json => @entity.to_json(:format => 'json') and return }
    end
  end
  
  # *Description*
  #  Creats an entity
  #   POST /entities
  #   POST /databases/entities
  def create
    begin
      super
      if @code == 400
        @msg, @code = report_errors(@entity, nil) 
      end
    rescue Exception => e
        @msg, @code = report_errors(@entity, nil) 
    end
    
    respond_to do |format|
      @msg = [(@@lookup[:Entity] % [@@base_url,  @entity.id]) + '.json'] if @code == 201
      format.json { render :json => @msg , :status => @code and return}
    end
    
  end  
  
  # *Description*
  #   Updates an entity
  #   PUT /entities/:id
  #   PUT /databases/:entities/:id
  def update
    begin
      super
    rescue ActiveRecord::StaleObjectError => e
      @msg = report_errors(nil, e)[0]
      @code = 409
    rescue Exception => e
      @msg, @code = report_errors(@entity, e)
    end
    
    respond_to do |format|
      @msg = @entity.to_json(:format => 'json') if @code == 200
      format.json { render :text => @msg, :status => @code and return }
    end
  end
  
  # *Description*
  #   Deletes an entity
  #   DELETE /entities/:id
  #   DELETE /databases/entities/:id
  #
  def destroy
    begin
      destroy_item(Entity, params[:id], params[:lock_version])
      @msg = 'OK'
      @code = 200
    rescue ActiveRecord::StaleObjectError => e
      @msg = report_errors(nil, e)[0]
      @code = 409
    rescue Exception => e
      @msg  = report_errors(nil, e)[0]
      @code = 500
    end
    
    respond_to do |format|
      format.json { render :json => @msg, :status => @code and return }
    end
    
  end
  
  protected
  
  def validate_rest_call
    
    if params[:entity]
      begin  
        params[:entity] = JSON.parse(params[:entity])
        params[:entity] = substitute_ids(params[:entity])
        check_id_conflict(params[:entity], params[:id])
        valid_entity?(params[:entity], params)
        # Get the database id from the entity resoure
        params[:database_id] = params[:entity][:database_id] if !params[:database_id]
      rescue MadbException => e
        render :json => report_errors(nil, e)[0], :status => e.code and return false
      rescue Exception => e
        render :json => report_errors(nil, e)[0], :status => 400 and return false
      end  
    end
        
    if params[:action] == 'create' or params[:action] == 'update'
          render :json => report_errors(nil,'Provide the entity resource for create/update')[0],
            :status => 400 and return false if !params[:entity]
    end
    
    if params[:action] == 'index'
      render :json => report_errors(nil,'GET /entities is not allowed, use GET /entities?database=id instead.')[0],
        :status => 400 and return false if !params[:database_id]
    end
    
    if params[:action] == 'destroy'
      render :json => report_errors(nil,'Provide lock_version for update/delete operations')[0],
        :status => 400 and return false if !params[:lock_version]
    end
    
    
    
      
    
    
    return true
  end
  
  def check_ids
    
    
    
    if params[:database_id]
      render :json => report_errors(nil,"Database[#{params[:database_id]}] does not exists.")[0], 
        :status => 404 and return false if !exists?(Database, params[:database_id])
    end
    
    if params[:database]
      render :json => report_errors(nil,"Database[#{params[:database]}] does not exists.")[0], 
        :status => 404 and return false if !exists?(Database, params[:database])
    end
    
    #FIXME
    # Order changed... For the test_delete case
    # where datbase_id is incorrect but entity id is correct.
    if params[:id]
      if !exists?(Entity, params[:id])
        render :json => report_errors(nil,"Entity[#{params[:id]}] does not exists.")[0],
          :status => 404 and return false
      end
    end
    
    
    
    return true;
  end
  
  
  def check_relationships
    if params[:database_id] and params[:id]
      render :json => report_errors(nil,"Entity[#{params[:id]}] does not belong to Database[#{params[:database_id]}]")[0],
        :status => 400 and return false if !related_to_each_other?(:database => params[:database_id],
                                                                  :entity => params[:id])
    end
    
    begin
      belongs_to_user?(session['user'], 
                    :database => params[:database_id],
                    :entity => params[:id])
    rescue MadbException => e
      render :json => report_errors(nil, e)[0], :status => 400 and return false
    end
    
    return true
  end
  
  # *Description*
  #   This method adjusts the incomilng request parameters so that they
  #   can be digested by the underlying existing code.
  #   For the conventions for its anatomy, please look at
  #   app/controllers/rest/rest_api_notes.txt
  #   First we check the required action by the REST call and then
  #   adjust or swap the parameters based on the type/length of the incoming
  #   call.
  #   Following adjustments are made:
  #   
  #
  def adjust_params()
    
    if params[:action] == 'index'
      return true;
    end
    
    if params[:action] == 'show'
      return true;
    end
    
    # If its one of the following:
    # POST /entities
    # POST /databases/entities
    if params[:action] == 'create'
      # If the database id is provided as a separate param or as part of the url,
      # Set that in to the database resource if not alredy provided.
      if params[:database_id] or params[:database]
        params[:entity][:database_id] = params[:database_id] || 
          params[:database] if !params[:entity][:database_id]
      end
      
      return true;
    end
    
    if params[:action] == 'update'
      return true;
    end
    
    if params[:action] == 'destroy'
      return true;
    end
    
    
    
    # In all cases, the request is not handled by this controller!
    render :text =>  "The requested action is \"#{params[:action]}\" " + 
      " on controller \"#{params[:controller]}\" while I am" + 
      " \"#{self.class.name}\" and cannot handle your request.",:status => 400 and return false;
    
  end
  
  protected
 # Overriden from LoginSystem in order to render custom message
  def access_denied
    render :json => %Q~{"errors": ["Please login to consume the REST API"]}~, :status => 401
  end
    
end
