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
#   This class provides the REST Interface to the relations resource
#   It is derived from the Admin::EntitiesController so that the functionality 
#   can be resued.
#   
#   
#   * /relations
#   * /relations?(parent|child)=id
#   * /entities/relations
#   * /databases/entities/relations
#   
# *Resource*
#   The relation resource has following form:
#  
#  * relation[parent_id]
#  * relation[child_id]
#  * relation[from_parent_to_child_name]
#  * relation[from_child_to_parent_name]
#  * relation[parent_side_type_id]
#  * relation[child_side_type_id]
#
#FIXME: GET /entities/relations should check whether the entity belongs to the 
# user or not
class Rest::RelationsController < Admin::EntitiesController
  
  include Rest::RestValidations
  include InstanceProcessor
  include Rest::UrlGenerator
  
  # Not needed. Provided by the parent controller
  #before_filter :login_required
  
  # Validate that its a valid rest call
  before_filter :validate_rest_call
  
  # Check the ids provided
  before_filter :check_ids
  
  # Check whether the ids relate togather
  before_filter :check_relationships
  
  # Adjust any parameters if needed for the existing code base.
  before_filter :adjust_params
  
  # GET /entities/:entity_id/relations
  # GET /databases/:database_id/entities/:entity_id/relations
  def index
    begin
      condition = "(parent_id=#{params[:entity_id]} or child_id=#{params[:entity_id]})"
      params[:conditions] = add_condition(params[:conditions], condition, :and)
      records = get_paginated_records_for(
      :for            => Relation,
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
      format.json { render :json => records.to_json(:format => 'json') and return}
    end
    
  end
  
  # GET /relations/:id
  # GET /entities/:entity_id/relations/:id
  # GET /databases/:database_id/entities/:entity_id/relations/:id
  def show
    begin
      get_relation(params[:id], params[:entity_id])
    rescue Exception => e
      @msg, @code = report_errors(nil, e)
      render :json => @msg, :status => @code and return
    end
    
 
    respond_to do |format|
      format.json { render :json => @relations.to_json(:format => 'json') and return }
    end
    
    
  end
  
  
  # POST /relations
  # POST /entities/relations
  # POST /databases/entities/relations
  def create
    begin
      add_link
      if @code == 400
        @msg, @code = report_errors(@relation, nil)
      end
    rescue Exception => e
      @msg, @code = report_errors(nil, e)
#      render :json => @msg, :status => @code and return
    end
    
    respond_to do |format|
      format.json do 
        @msg = [(@@lookup[:Relation] % [@@base_url, @relation.id]) + '.json'] if @code == 201
        render :json => @msg, :status => @code and return 
      
      end
      
    end
    
  end
  
  # GET /relations/:id
  # GET /entities/:entity_id/relations/:id
  # GET /databases/:database_id/entities/:entity_id/relations/:id
  def update
    begin
      add_link
      if @code == 400
        @msg, @code = report_errors(@relation, nil)
      end
    rescue ActiveRecord::StaleObjectError => e
      @msg = report_errors(nil, e)[0]
      @code = 409
    rescue Exception => e
      @msg, @code = report_errors(nil, e)
    end
    
    respond_to do |format|
      format.json do 
        @msg = Relation.find(params[:id]).to_json(:foramt => 'json') if @code == 200
        render :json => @msg, :status => @code and return 
      end
    end
  end
  
  
  def destroy
    
    begin
#    This code is not needed because check_relationships filter checks this.      
#    if params[:entity_id]
#      #check if the link to delete id asked from a related entity (source_id)
#      params_validity_count = Relation.count(:conditions => "id = #{params[:id]} and (parent_id=#{params[:entity_id]} or child_id=#{params[:entity_id]})")         
#      if params_validity_count.to_i!=1
#        raise BadResource.new, 'Bad Reqeust (Multiple relation records found.)' 
#      end
#    end
      
      destroy_item(Relation, params[:id], params[:lock_version])
      @msg = 'OK'
      @code = 200
    rescue ActiveRecord::StaleObjectError => e
      @msg = report_errors(nil, e)[0]
      @code = 409
    rescue MadbException => e
      @msg = report_errors(nil, e)[0]
      @code = e.code
    rescue Exception => e
      @msg = report_errors(nil, e)[0]
      @code = 500
    end
    
    
    respond_to do |format|
      format.json { render :json => @msg, :status => @code and return }
    end
  end
  
  
  # *Description*
  #   Validates that its a valid REST call. 
  #
  def validate_rest_call
    
    # Parse the incoming JSON
    if params[:relation]
      begin
        params[:relation] = JSON.parse(params[:relation])
        params[:relation] = substitute_ids(params[:relation])
        check_id_conflict(params[:relation], params[:id])
        valid_relation?(params[:relation], params)
      rescue MadbException => e
        render :json => report_errors(nil,e)[0], :status => e.code and return false
      rescue Exception => e
        render :json => report_errors(nil,e)[0], :status => 400 and return false
      end
    end
      
    
    if params[:action] == 'index'
      # if the access URL is:
      # GET /relations
      render :json => report_errors(nil, 'GET /relatiosn is not allowed, use GET /entities/:entity_id/relations instead')[0],
        :status => 400 and return false if !params[:entity_id]
      
    end
    
    
    if params[:action] == 'create' or params[:action] == 'update'      
      render :json => report_errors(nil, 'Provide the relation resource to be created/updated')[0],
        :status => 400 and return false if !params[:relation]
      
#      # If its a nested call like /entities/relations or /databases/entities/relations
#      # and parent or child parameter is provided, then the entity id that is part of the url
#      # would be used as relation
#      if params[:child] and params[:entity_id] and params[:action] == 'create'
#        params[:relation][:parent_id] = params[:entity_id]
#        params[:relation][:child_id] = params[:child]
#        
#      elsif params[:parent] and params[:entity_id] and params[:action] == 'create'
#        params[:relation][:child_id] = params[:entity_id]
#        params[:relation][:parent_id] = params[:parent]
#      end

    end
    
    if params[:action] == 'destroy'
      render :json => report_errors(nil, 'Provide lock_version for update/delete operations')[0],
        :status => 400 and return false if !params[:lock_version]
    end
    
  end
  
  # *Description*
  #   Checks whether the ids provided are valid or not.
  #
  # FIXME: This should check that the given entity or relation id
  # belongs to the current user.
  def check_ids
    
    if params[:id]
      render :json => report_errors(nil,"Relation[#{params[:id]}] does not exists")[0], 
        :status => 404 and return false if !Relation.exists?(params[:id].to_i)
    end
    
    if params[:entity_id]
      render :json => report_errors(nil,"Entity[#{params[:entity_id]}] does not exists")[0],
        :status => 404 and return false if !Entity.exists?(params[:entity_id].to_i)
    end
    
    if params[:database_id]
      render :json => report_errors(nil,"Database[#{params[:database_id]}] does not exists")[0], 
        :status => 404 and return false if !Database.exists?(params[:database_id].to_i)
    end
    
    if params[:entity]
      render :json => report_errors(nil,"Entity[#{params[:entity]}] does not exists")[0],
        :status => 404 and return false if !Entity.exists?(params[:entity].to_i)
    end
    
    if params[:parent]
      render :json => report_errors(nil,"Entity[#{params[:parent]}] does not exists")[0],
        :status => 404 and return false if !Entity.exists?(params[:parent].to_i)
    end
    
    if params[:child]
      render :json => report_errors(nil,"Entity[#{params[:child]}] does not exists")[0],
        :status => 404 and return false if !Entity.exists?(params[:child].to_i)
    end
    
    
    
    # In all other cases, its ok
    return true
    
  end
  
  # *Description*
  #   This validates the relationships among the provided items.
  #
  def check_relationships
    
    if params[:entity_id] and params[:id]
      render :json => report_errors(nil,"Relation[#{params[:id]}] does not belong to Entity[#{params[:entity_id]}]")[0],
        :status => 400 and return false if !related_to_each_other?(:entity => params[:entity_id], :relation => params[:id])
    end
    
    if params[:database_id] and params[:entity_id]
      render :json => report_errors(nil,"Entity[#{params[:entity_id]}] does not belongs to Database[#{params[:database_id]}]")[0],
        :status => 400 and return false if !related_to_each_other?(:database => params[:database_id], :entity => params[:entity_id])
    end
    
    begin
      belongs_to_user?(session['user'], 
                    :entity => params[:entity_id],
                    :relation => params[:id])
    rescue MadbException => e
      render :json => report_errors(nil, e)[0], :status => 400 and return false
    end
    
    # In all other cases, its ok
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
  def adjust_params  
    #if request is like this:
    # GET /relations
    # GET /entities/relations
    # GET /databases/entities/relations
    if params[:action] == 'index'
      
      # If it is 
      # GET /relations
      # Then we cannot sevice this request, must specify the entity.
#      if !params[:database_id] and !params[:entity_id]
#        render :text => 'GET /relations is not available', :status => 400
#        return false;
#      end

      # But in the remaining two cases:
      #   * /entities/relations
      #   * /databases/entities/relations
      # Allow the class
      return true;
    end
    
    # if it is:
    # GET /relations
    # GET /entities/relations
    # GET /databases/entities/relations/
    # Becasue show needs to have an ID, therefore
    # any of the above URL will do and no context is needed.
    #FIXME: What other possibility the show action might face?
    if params[:action] == 'show'
      return true;
    end
    
    #If its like this:
    # POST /relations
    # POST /entities/relations
    # POST /databases/entities/relations
    # NOTE: For now, the relation resource should be totally complete
    #       even if the call is being as a nested resource.
    #
    if params[:action] == 'create'
      
      #if it is like this:
      # POST /relations
      # Then the relations resource should be complete in
      # every respect.
      if !params[:database_id] and !params[:entity_id]
        #return true if valid_relation_resource?
        # Otherwise, the resource is not vaild and we need to tell the user
        #render :json => report_errors(nil, 'The provided realtion resource is incomplete')[0], 
         # :status => 400 and return false;
      end
      
      # But if its something like this:
      # POST /entities/:entity_id/relations
      # POST /databases/entities/:entity_id/relations
      #
      if params[:database_id] or params[:entity_id]
        # Then if the relation resource is valid, 
        # the entity_id parameter is altogather ignored.
        #return true if valid_relation_resource?  
      end
      return true
    end
    
    # if its either of these:
    # PUT /relations
    # PUT /entities/relations
    # PUT /databases/entities/relations
    #
    if params[:action] == 'update'
      # Set the params[:relation_id] because
      # the underlying Admin::EntitiesController#add_link function
      # expects it
      params[:relation_id] = params[:id] and return true;
    end
    
    # If it is either of these:
    #   DELETE /relations
    #   DELETE /entities/relations
    #   DELETE /databases/entities/relations
    #
    if params[:action] == 'destroy'
      
      # For now, you can only make a nested call.
      #PENDING: This would change when the rest call would include the user
      # authenticiy information which would help to determine whether the 
      # relation being deleted belongs to the user or not.
      if !params[:entity_id]
        render :json => report_errors(nil, 'DELETE /relations call is not available for now. Call DELETE /entities/relations instead')[0],
          :status => 400 and return false
      end
      
      params[:source_id] = params[:entity_id]
      return true;
      
    end
    
    # In all cases, the request is not handled by this controller!
    render :json => report_errors(nil, "The requested action is \"#{params[:action]}\" " + 
      " on controller \"#{params[:controller]}\" while I am" + 
      " \"#{self.class.name}\" and cannot handle your request.")[0],:status => 400 and return false;
    
  end
  
  
  # *Description*
  #   This function returns all the relations of the given entity.
  #   FIXME: We do not check the ownership of the enitty yet!
  #   FIXME: We do not check whether the entity belongs to the same database
  #          if a nested call /databases/entities/relations is made.
  #
#  def list_relations_for_entity(entity_id)
#    
#    @relations = Relation.find( :all, 
#                                :offset => params['start-index'],
#                                :limit => params['max-results'],
#      :conditions => ["parent_id = ? or child_id = ?", entity_id, entity_id])
#  end
  
  # *Description*
  #   This function gets a single relation. If the entity id is provided,
  #   Then it is ensured that the relation is for tha entity.
  #
  def get_relation(relation_id, entity_id = nil)
    if entity_id
      @relations = Relation.find(:first, :conditions => 
          ["id = ? and child_id = ? or parent_id = ?", relation_id, entity_id, entity_id])
    else
      @relations = Relation.find(:first, :conditions => 
        ["id = ?", relation_id])
    end
  end
  
  protected
 # Overriden from LoginSystem in order to render custom message
  def access_denied
    render :json => %Q~{"errors": ["Please login to consume the REST API"]}~, :status => 401
  end
  
end
