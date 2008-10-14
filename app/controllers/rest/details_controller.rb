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
#   This class provides the REST Interface to the details resource
#   It is derived from the Admin::DetailsController so that the functionality 
#   can be resued.
#   
#   1- GET      /databases/:database_id/details
#   2- GET      /details/:id
#   3- GET      /databases/:database_id/details/:id
#   3- PUT      /details/:id
#   4- POST     /details?database=2  (creates in system)
#   5- DELETE   /details/:id         (deletes from system)
#   6- GET      /databases/:database_id/details
#   7- GET      /databases/:database_id/details/:id
#   8- PUT      /databases/:database_id/details/:id
#   9- POST     /databases/:database_id/details       (creates in system)
#  10- DELETE   /databases/:database_id/details/:id   (deletes from system)
#  11- GET      /entities/:entity_id/details
#  12- GET      /entities/:entity_id/details/:id
#  13- PUT      /entities/:entity_id/details/:id
#  14- POST     /entities/:entity_id/details?detail=2 (links detail to entity_id)
#  15- DELETE   /entities/:entity_id/details/:id (unlinks detail from entity_id)
#  16- GET      /databases/:database_id/entities/:entity_id/details
#  17- GET      /databases/:database_id/entities/:entity_id/details/:id
#  18- PUT      /databases/:database_id/entities/:entity_id/details/:id
#  19- POST     /databases/:database_id/entities/:entity_id/details?detail=2 (links detail to entity_id)
#  20- DELETE   /databases/:database_id/entities/:entity_id/details/:id
#
    
#   
#   
#   
#   
#          
# *Resource*
#   FIXME: This resource defination should be reviewed which currently mentions data_type_ids.
#   The detail[database_id] should also be included and accounted for in 
#   validate_rest_call
#   
#   The detail resource has following form:
#  detail[name]
#  
#  detail[data_type_id]
#  detail[database_id] optional if provided in database parameter

class Rest::DetailsController < Admin::DetailsController
  
  # Not needed. Provided by the parnet controller
  #before_filter :login_required
  
  before_filter :validate_rest_call
  # This filter only checks that the ids of the request paramters have
  # corresponding records.
  before_filter :check_ids
  
  # At second level, we check the relationships among the items.
  before_filter :check_relationships
  
  # This is required to adjust the parameters.
  before_filter :adjust_params
  # Incldue the RestValidations module
  include Rest::RestValidations
  include Rest::UrlGenerator
  include InstanceProcessor
  
  # *Description*
  #   Gets all the details
  #   by:
  #   
  #   * GET details/
  #   * GET /entities/:entity_id/details
  #   * GET /databases/:database_id/entities/:entity_id/id
  #       escape sequences
  def index
    
     begin
       if params[:database_id]
         results = get_details_for(:database => params[:database_id])
       elsif params[:entity_id]
         results = get_details_for(:entity => params[:entity_id])
       end
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
      render :json => report_errors(nil, e)[0], :status => 400 and return
    end
    
    respond_to do |format|
      format.json { render :json => @details.to_json(:format => 'json') and return }
    end
  end
  
  # *Description*
  #  Creats an entity
  #   POST /entities
  #   POST /databases/entities
  def create
    puts @type_of_call
    if @type_of_call == :creation
      begin
        super
        if @code == 500
          @msg, @code = report_errors(@details, nil)
        end
      rescue Exception => e
        @msg, @code = report_errors(@details, e)
      end
    elsif @type_of_call == :linkage
      begin
        link_detail
      rescue Exception => e
        @msg, @code = report_errors(nil, e)
      end
    end
    
    respond_to do |format|
      format.json do 
        if @type_of_call == :creation and @code == 201
          @msg = [@@lookup[:Detail] % [@@base_url, @details.id] + '.json']
          
        end
        render :json => @msg, :status => @code and return if !performed?
      end
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
      @msg, @code = report_errors(@details, e)
    end
    
    respond_to do |format|
      @msg = @details.to_json(:format => 'json') if @code == 200
      format.json { render :json => @msg, :status => @code and return }
    end
  end
  
  # *Description*
  #   Deletes an entity
  #   DELETE /entities/:id
  #   DELETE /databases/entities/:id
  #
  def destroy
    
    
    
    if @type_of_call == :creation
      begin
        #super
        destroy_item(Detail, params[:id], params[:lock_version])
        @msg = 'OK'
        @code = 200
      rescue ActiveRecord::StaleObjectError => e
        @msg = report_errors(nil, e)[0]
        @code = 409
      rescue Exception => e
        @msg, @code = report_errors(nil, e)
      end
    elsif @type_of_call == :linkage
      begin
        unlink_detail
        @msg = 'OK'
        @code = 200
      rescue Exception => e
        #puts "CAME HERE.........#{@type_of_call}"
        @msg, @code = report_errors(nil, e)
      end
    end
    
    
    #render :json => @msg, :status => @code and return
    
    
    
    respond_to do |format|
      format.json { render :json => @msg, :status => @code and return }
    end
    
  end
  
  protected
  
  
  def validate_rest_call
    
    # Because this details controller can do both, creating/deleting a detail
    # from the system or linking/unlinking a detail from an entity, it is to be 
    # judged earlier the type of call requested. This variable serves the purpsoe
    # of indicating the type of operation to be performed. If its creation/deletion,
    # it is set to :creation, otherwise to :linkage
    @type_of_call = :creation
    
    # This little hack to allow the /instances/:instance_id/details and others:
    if params[:instance_id]
      render :json => report_errors(nil, "Instance[#{params[:instance_id]}] does not exists")[0],
        :status => 400 and return false if !Instance.exists?(params[:instance_id])
      # Get the entity of the instacne and use it instead!
      params[:entity_id] = Instance.find(params[:instance_id]).entity_id.to_i
    end
    
    # If the detail is addressed along with entity in a nested call,
      # it must be linked
      if params[:entity_id] and %w{create destroy}.include? params[:action]
        @type_of_call = :linkage #and return true
      end
    
#    # Here we try to convert the incoming JSON into a hash
#    # If the intended action is creation/updation or 
#    if %w{create update}.include?(params[:action]) and @type_of_call == :creation
#      
#      render :text => 'Provide the Detail resource to be created/updated',
#        :status => 400 and return false if !params[:detail]
#      
#      begin
#        params[:detail] = JSON.parse(params[:detail])
#      rescue Exception => e
#        render :text => e.message, :status => 400 and return false
#      end
#    end
    
    
    if params[:detail]
      begin
        params[:detail] = JSON.parse(params[:detail])
        params[:detail] = substitute_ids(params[:detail])
        valid_detail?(params[:detail], params)
        check_id_conflict(params[:detail], params[:id])
      rescue MadbException => e
        render :json => report_errors(nil, e)[0], :status => e.code and return false
      rescue Exception => e
        render :json => report_errors(nil, e)[0], :status => 400 and return false
      end
    end
    
    
    case(params[:action])
    when 'index'
      #   1- GET      /details?database=4
      if !params[:database_id] and !params[:entity_id]
        render :json => report_errors(nil, 'GET /details is not allowed, use GET /details?database=id instead.')[0],
          :status => 400 and return false;
      end
      
    when 'create'
        render :json => report_errors(nil, 'Provide the detail resource to be created/updated/linked')[0],
          :status => 400 and return false if !params[:detail]
        
        #if not a nested call for creation, then the database id should be
        # within resource
#        if !params[:database_id]
#          render :json => report_errors(nil, 'Provide database id as a nested REST call or mention it in detail resource')[0],
#            :status => 400 and return false if !params[:detail][:database_id]
#          
#          # pick the database id from the detail resource
#          params[:database_id] = params[:detail][:database_id]
#        end
        

    when 'update'
      render :json => report_errors(nil, 'Provide the detail resource to be created/updated')[0],
        :status => 400 and return false if !params[:detail]
      
    when 'destroy'
      if @type_of_call != :linkage
        render :json => report_errors(nil, "Provide lock_version for update/delete operations")[0],
          :status => 400 and return false if !params[:lock_version]
      end
    end
    
    

    # In all other cases, return true
    return true
  end
  
  # *Description*
  #   This method is used as a before filter and checks whether the provided
  #   ids exists or not.
  #
  def check_ids
     
    
    # If its a call:
    # /databases/details
    # /databases/entities/details
    
    
    if params[:database_id]
      render :json => report_errors(nil, "Database[#{params[:database_id]}] does not exists")[0],
          :status => 404 and return false if !exists?(Database, params[:database_id])
    end
    
#    if params[:database]
#      render :text => "Database[#{params[:database]}] does not exists",
#          :status => 400 and return false if !exists?(Database, params[:database])
#    end
    
    if params[:entity_id]
      render :json => report_errors(nil, "Entity[#{params[:entity_id]}] does not exists")[0],
          :status => 404 and return false if !exists?(Entity, params[:entity_id])
    end
    
    
    if params[:id]
      render :json => report_errors(nil, "Detail[#{params[:id]}] does not exists")[0],
          :status => 404 and return false if !exists?(Detail, params[:id])
    end
    
    if params[:detail_id]
      render :json => report_errors(nil, "Detail[#{params[:detail_id]}] does not exists")[0],
          :status => 404 and return false if !exists?(Detail, params[:detail_id])
    end
    
    
    
    return true
    
  end
  
  
  # *Description*
  # This function ensures that in case of nested calls, the parameters are 
  # related to each other.
  #FIXME: Make it more solid so that nothing slips out.
  def check_relationships
    
    begin
      belongs_to_user?(session['user'], 
        :database => params[:database_id],
        :entity => params[:entity_id],
        :detail => params[:id]
                    )
    rescue MadbException => e
      render :json => report_errors(nil, e)[0], :status => 400 and return false
    end   
    
    if params[:database_id] and params[:entity_id]
      if !related_to_each_other?(:database =>params[:database_id],:entity => params[:entity_id])
        render :json => report_errors(nil,"Entity[#{params[:entity_id]}] does not belongs to Database[#{params[:database_id]}]")[0],
          :status => 400 and return false
      end
    end
    
    if params[:entity_id] and params[:id]
      if !related_to_each_other?(:entity =>params[:entity_id],:detail => params[:id])
        render :json => report_errors(nil, "Detail[#{params[:id]}] does not belong to Entity[#{params[:entity_id]}]")[0],
          :status => 400 and return false
      end
    end
    
    if params[:database_id] and params[:id]
      if !related_to_each_other?(:database =>params[:database_id],:detail => params[:id])
        render :json => report_errors(nil, "Detail[#{params[:id]}] does not belong to Database[#{params[:database_id]}]")[0],
          :status => 400 and return false
      end
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
    
    # If any of the call:
    # GET /details
    # GET /entities/details
    # GET /databases/entities/details
    if params[:action] == 'index'
      params[:db] = params[:database_id] and return true if params[:database_id] 
      return true
    end
    
    if %w{create update}.include? params[:action]
      params[:db] = params[:detail][:database_id] if params[:detail][:database_id]
    end
    
    
      
     
     
    # If its either:
    # GET /details/:id
    # GET /entitites/details/:id
    # GET /databases/entities/details/:id
    #
    if params[:action] == 'show'
      #FIXME: Add the code in the underlying controller
      # So that it cares about the provided database and
      # entity
      return true;
    end
    
    # If its either:
    # POST /details
    # POST /entities/details
    # POST /databases/details
    if params[:action] == 'create'
#      # If its a call of:
#      # POST /details
#      # Then it is not allowed
#      if !params[:database_id] and !params[:entity_id]
#        render :text => 'POST /details is not allowed.', :status => 400 and return false
#      end
      
      # Set the for_entity and db params if their correspondings are provided.
      params[:for_entity] = params[:entity_id] if params[:entity_id]  
      params[:db] = params[:database_id] ||params[:database] if params[:database_id] or params[:database]
      params[:details] = params[:detail] if params[:detail]
      return true;
    end
    
    # if it is one of these:
    # PUT /details/:id
    # PUT /entities/:entity_id/details/:id
    # PUT /databases/:database_id/entities/:entity_id/details/:id
    if params[:action] == 'update'
      
      params[:db] = params[:database_id] if params[:database_id]
      params[:for_entity] = params[:entity_id] if params[:entity_id]
      params[:details] = params[:detail] if params[:detail]
      return true
    end
    
    if params[:action] == 'destroy'
      return true
    end
    
   
    # In all cases, the request is not handled by this controller!
    render :text =>  "The requested action is \"#{params[:action]}\" " + 
      " on controller \"#{params[:controller]}\" while I am" + 
      " \"#{self.class.name}\" and cannot handle your request.",:status => 400 and return false;
    
  end
  
    # *Description*
  #   Adds and existing detail to this entity
  #   
  def link_detail
    entity = Entity.find params[:entity_id]

    # Pick sensible detaults if not provided.
    # A Detail is active by default
#    params[:status_id] = 1 if !params[:status_id]
    # And visible also
#    params[:display_in_list_view] = true if !params[:display_in_list_view]
    # And has only one maximum allowed values.
#    params[:maximum_number_of_values] = 1 if !params[:maximum_number_of_values]
    
      

    if entity.details.collect{|d| d.detail_id.to_i}.include?  params[:detail_id].to_i
      raise "Detail[#{params[:detail_id]}] already linked to Entity[#{entity.id}]"
      #@msg = report_error(nil,'Bad Request (detail already belongs to the entity)')[0] 
      #@code = 400
      #return
    end

    detail = Detail.find params[:detail][:detail_id]
    if params[:detail][:status_id]
      status = DetailStatus.find params[:detail][:status_id]
    else
      status = DetailStatus.find(1)
    end

    number_of_details = entity.details.length
    display_order = number_of_details + 1
    
    params[:detail][:display_order] = display_order if !params[:detail][:display_order]
    
    entity_detail = EntityDetail.new(params[:detail])

    entity_detail.detail = detail
    entity_detail.entity = entity
    entity_detail.detail_status = status
    
    entity_detail.save!
   
    @msg = 'OK'
    @code = 200
    
  end
  
  # *Description*
  #   Unlinks the detail from an entity. Or in other words, unlinks a column
  #   from a table. Becuase an entity can use many existing details, it simply
  #   unlinks it them.
  #
  def unlink_detail
    entity = nil
    
    to_delete = Detail.find params[:id]
    entity = Entity.find params[:entity_id]
    entity.details.delete to_delete
    
  end
  
  
  def get_details_for(options={})
    if options[:database]
      params[:conditions] = add_condition(params[:conditions], 
                            "(database_id=#{options[:database]})", :and)      
      
                          
        results = get_paginated_records_for(
        :for => Detail,
        :star_index => params[:start_index], 
        :max_results => params[:max_results],
        :order_by => params[:order_by], 
        :direction => params[:direction], 
        :conditions => params[:conditions])
      return results
    end
    
    # If for entity
    if options[:entity]
      entity = Entity.find(options[:entity])
      
      results = {}
      results[:total_resources] = entity.details.length
      results[:resources_returned] = entity.details.length
      results [:start_index] = 0
      results[:order_by] = nil
      results[:direction] = nil
      results[:resources] = entity.details.dup
      return results
    end
  end

  protected
 # Overriden from LoginSystem in order to render custom message
  def access_denied
    render :json => %Q~{"errors": ["Please login to consume the REST API"]}~, :status => 401
  end
  
  
end


