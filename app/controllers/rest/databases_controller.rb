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
#   This class provides the REST Interface to the databases resource
#   It is derived from the Admin::DatabasesController so that the functionality 
#   can be resued.
#   
#   
#  01- GET         /databases
#  02- GET         /accounts/:account_id/databases
#  03- GET         /databases/:id
#  04- GET         /accounts/:account_id/databases/:id
#  05- POST        /databases/
#  06- POST        /accounts/:account_id/databases
#  07- PUT         /databases/:id
#  08- PUT         /accounts/:account_id/databases
#  09- DELETE      /databases/:id
#  10- DELETE      /accounts/:account_id/databases
#  
# *Resource*
# In requests for updating/creating a database, a databae takes the following
# form:
#   database[name]
#

class Rest::DatabasesController < Admin::DatabasesController
  
  include Rest::RestValidations
  include Rest::UrlGenerator
  include InstanceProcessor
  
  # Not needed, provided by the parent controller
  #before_filter :login_required
  
  before_filter :validate_rest_call
  
  before_filter :check_ids
  
  before_filter :check_relationships
  # This is required to adjust the parameters.
  before_filter :adjust_params
  
  
  # *Description*
  #   Gets all the databases
  #   by:
  #   
  #   * GET /databases
  #
  def index
    begin
      params[:conditions] = add_condition(params[:conditions], 
                            "(account_id=#{params[:account_id]})", :and)
                          
      results = get_paginated_records_for(
        :for => Database,
        :star_index => params[:start_index], 
        :max_results => params[:max_results],
        :order_by => params[:order_by], 
        :direction => params[:direction], 
        :conditions => params[:conditions])
    rescue Exception => e
      render :json => report_errors(nil, e)[0], :status => 500
    end
   
    respond_to do |format|
      format.json { render :json => results.to_json(:format => 'json')}
    end
  end
  
  # *Description*
  #   Gets a particulalr database
  #   GET /databases/:id
  #
  def show
    begin
      super
    rescue Exception => e
      @msg, @code = report_errors(nil, e)
      render :json => @msg, :status => @code and return
    end
    
     
    respond_to do |format|
      format.json { render :json => @database.to_json(:format => 'json') and return }
    end
    
  end
  
  # *Description*
  #  Creats a database
  #   POST /databases
  def create
    begin
      super
    rescue Exception => e
      @msg, @code = report_errors(@database, e)
    end
    
    respond_to do |format|
      @msg = [(@@lookup[:Database] % [@@base_url, @database.id]) + '.json'] if @code == 201
      format.json { render :text => @msg , :status => @code and return }
    end
  end  
  
  # *Description*
  #   Updates a dataabase
  #   PUT /databases/:id
  def update
    begin
      super
      @msg = 'OK'
      @code = 200
    rescue ActiveRecord::StaleObjectError => e
      @msg = report_errors(nil, e)[0]
      @code = 409
    rescue Exception => e
      @msg, @code = report_errors(@database, e)
    end
    
    respond_to do |format|
      @msg = @database.to_json(:format => 'json') if @code == 200
      format.json { render :text => @msg, :status => @code and return }
    end
  end
  
  # *Description*
  #   Deletes a database
  #   DELETE /databases/:i
  def destroy
    begin
      destroy_item(Database, params[:id], params[:lock_version])
      @msg =  'OK'
      @code = 200
    rescue ActiveRecord::StaleObjectError => e
      @msg =  report_errors(nil, e)[0]
      @code = 409
    rescue Exception => e
      @msg =  report_errors(nil, e)[0]
      @code = 500
    end
    
    respond_to do |format|
      format.json { render :json => @msg, :status => @code and return }
    end
    
  end
  
  protected
  
  # *Description*
  #   This function validates the rest call semantics.
  #
  def validate_rest_call
    
    # If its an index
    if params[:action] == 'index'
      params[:account_id] = session['user'].account_id if !params[:account_id]
      
      render :json => report_errors(nil, 'GET /databases not allowed. Call GET /accounts/:account_id/databases instead')[0],
        :status => 400 and return false if !params[:account_id]
    end
    
    if %w{create update}.include? params[:action]
      render :json => report_errors(nil, 'Provide the database resource to be created/updated')[0],
        :status => 400 and return false if !params[:database]
      begin
        params[:database] = JSON.parse(params[:database])
        params[:database] = substitute_ids(params[:database])
        check_id_conflict(params[:database], params[:id])
        valid_database?(params[:database], params)
      rescue MadbException => e
        #puts e.backtrace
        render :json => report_errors(nil, e)[0], :status => e.code and return false
      rescue Exception => e
        #puts e.backtrace
        render :json => report_errors(nil, e)[0], :status => 400 and return false
      end
      
    end
    
    if params[:action] == 'destroy'
      render :json => report_errors(nil, 'Provide lock_version for update/delete operations')[0],
        :status => 400 and return false if !params[:lock_version]
    end
    
    
  end
  
  # *Description*
  #   This method is used as a before filter and checks whether the provided
  #   ids exists or not.
  def check_ids
    
    if params[:id]
      render :json => report_errors(nil,"Database[#{params[:id]}] does not exists")[0],
          :status => 404 and return false if !Database.exists?(params[:id])
    end
    
    if params[:account_id]
      render :json => report_errors(nil, "Account[#{params[:account_id]}] does not exists")[0],
          :status => 404 and return false if !Account.exists?(params[:account_id])
    end
        
    return true
  end
  
  def check_relationships
    
    if params[:account_id] and params[:id]
      render :json => report_errors(nil, "Database[#{params[:id]}] does not belong to Account[#{params[:account_id]}]")[0],
        :status => 400 and return false if !related_to_each_other?(:account => params[:account_id], :database => params[:id])
    end
    
    begin
      belongs_to_user?(session['user'], 
                    :account => params[:account_id],
                    :database => params[:id])
    rescue MadbException => e
      render :json => report_errors(nil, e)[0], :status => 400 and return false
    end
    
    


    
    return true;
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
    
    if params[:action] == 'create'
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


