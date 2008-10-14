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
#   Provides the users resource through REST interface.
#

require 'json' 

#FIXME: Make it a nested resoruce of accouunt
# It is standing isolated because intially, raphael told not to expose accounts
# but as now we are exposing them, it would be better this to be nested
# resource of accounts

class Rest::UsersController < Admin::UsersController

  include Rest::RestValidations
  include Rest::UrlGenerator
  include InstanceProcessor
  
  # Not needed. Provided by the parent controller
  #before_filter :login_required
  
  before_filter :validate_rest_call
  
  before_filter :check_ids
  
  before_filter :check_relationships
  
  before_filter :adjust_params
  
  def index
    begin
      condition = "(account_id=#{params[:account_id]})"
      params[:conditions] = add_condition(params[:conditions], condition, :and)
      records = get_paginated_records_for(
      :for            => User,
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
      format.json { render :json => records.to_json(:format => 'json'), :status => 200 and return}
    end
    
  end
  
  def show
    @user = User.find(params[:id])
    
    respond_to do |format|
      format.json { render :json => @user.to_json(:format => 'json') and return}
    end
  end
  
  def create
    begin
      super
      if @code == 400
        @msg, @code = report_errors(@user, nil)
      end
    rescue Exception => e
      render :json => report_errors(nil, e)[0], :status => 500 and return
    end
    
    respond_to do |format|
      format.json do 
        @msg = [(@@lookup[:User] % [@@base_url, @user.id]) + '.json'] if @code == 201
        render :json => @msg, :status => @code and return 
      end
    end
  end
  
  def update
    begin 
      super
      if @code == 400
        @msg, @code = report_errors(@users, nil)
      end
      if @code == 200
        @msg = @users.to_json(:format => 'json')
      end
    rescue ActiveRecord::StaleObjectError => e
      @msg = report_errors(nil, e)[0]
      @code = 409
    rescue Exception => e
      @msg = report_errors(@users, e)[0]
      @code = 400
    end
    
    respond_to do |format|
      format.json do 
        render :json => @msg, :status => @code and return
      end
    end
  end
  
  def destroy

    user_to_destroy = User.find params[:id]
    
    if user_to_destroy.user_type.name == 'primary_user'
      render :json => report_errors(nil,'Primary User cannot be deleted')[0],
        :status => 403 and return
    end
    
# Commented out to disable optimistic locking
    #    begin
#      destroy_item(User, params[:id], params[:lock_version])
#      @msg = 'OK'
#      @code = 200
#    rescue ActiveRecord::StaleObjectError => e
#      @msg = report_errors(nil, e)[0]
#      @code = 409
#    rescue MadbException => e
#      @msg = report_errors(nil, e)[0]
#      @code = e.code
#    rescue Exception => e
#      @msg = report_errors(nil, e)[0]
#      @code = 500
#    end
    
    begin
      user_to_destroy.destroy
      @msg = 'OK'
      @code = 200
    rescue Exception => e
      @msg = report_errors(nil, e)[0]
      @code = 500
    end
    
    respond_to do |format|
      format.json { render :json => @msg, :status => @code and return }
    end
    
  end
  
  
  
  protected
  #FIXME: Should be in accordance with Ticket#68
  def validate_rest_call
    
    # We try to get the account id from the user 
    # 
    #params[:account_id] = session['user'].account_id if !params[:account_id]
    #FIXME: We should be able to do only GET /users/
    #If GET /users
    if params[:action] == 'index'
      render :json => report_errors(nil, 'GET /users not allowed, use GET accounts/:account_id/users instead')[0],
      :status => 400 and return false if !params[:account_id]
    end
    
    # If POST or PUT, must mention user resource in json
    if %w{create update}.include? params[:action]
      render :json => report_errors(nil, 'Provide user resource to be created/updated')[0],
        :status => 400 and return false if !params[:user]
      
      # Parse the JSON
      begin
        params[:user] = JSON.parse(params[:user])
        params[:user] = substitute_ids(params[:user])
        check_id_conflict(params[:user], params[:id])
        valid_user?(params[:user], params)
      rescue MadbException => e
        render :json => report_errors(nil, e)[0], :status => e.code and return false
      rescue Exception => e
        render :json => report_errors(nil, e)[0], :status => 400 and return false
      end
      
      
    end

# Commented out to disable optimistic locking    
#    if params[:action] == 'destroy'
#      render :json => report_errors(nil, 'Provide lock_verion for update/delete operations')[0], 
#        :status => 400 and return false if !params[:lock_version]
#    end
    
    # In all ohter cases, its ok
    return true;
    
  end
  
  def check_ids
    if params[:id]
      render :json => report_errors(nil, "User[#{params[:id]}] does not exists")[0],
        :status => 404 and return false if !User.exists?(params[:id].to_i)
    end
    
    if params[:account_id]
      render :json => report_errors(nil, "Account[#{params[:account_id]}] does not exists")[0],
        :status => 404 and return false if !Account.exists?(params[:account_id].to_i)
    end
    
    # In all other cases, its ok
    return true;
  end
  
  def check_relationships
    if params[:account_id] and params[:id]
      render :json => report_errors(nil,"User[#{params[:id]}] does not belong to Account[#{params[:account_id]}]")[0],
        :status => 400 and return false if !related_to_each_other?(:account => params[:account_id], :user => params[:id])
    end
    
    begin
      belongs_to_user?(session['user'], 
                    :account => params[:account_id],
                    :user => params[:id])
    rescue MadbException => e
      render :json => report_errors(nil, e)[0], :status => 400 and return false
    end
    
    return true
  end
  
  def adjust_params
    
    # if a GET /users
    if params[:action] == 'index'
      return true
    end
    
    return true
    
  end
  
  protected
 # Overriden from LoginSystem in order to render custom message
  def access_denied
    render :json => %Q~{"errors": ["Please login to consume the REST API"]}~, :status => 401
  end
end

