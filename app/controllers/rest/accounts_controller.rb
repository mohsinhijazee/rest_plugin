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
# This controller handls the accounts on the system
# Questions:
#   * Whether to expose this controller?
#      * If so, how do we authenticate?
#   * Do we allow deletion of accounts?
#   
# Most probably, this controller would only be accessible to 
# the SUPER USER.
#
# FIXME: If a record is not found, how to respond?
# FIXME: How to return the status codes?

class Rest::AccountsController < Rest::RestController
  
 
 before_filter :validate_rest_call
 before_filter :check_ids
 before_filter :check_relationships
  
  # GET accounts/1
  # GET accounts/1.xml
  # GET accounts/1.json
  def show
    begin
      @resource = Account.find(params[:id])
      render :response => :GET
    rescue Exception => e
      @error = process_exception(e)
      render :response => :error
    end
  end
  
  # GET accounts/
  # GET accounts.xml
  # GET accounts.json
  def index
    begin
      
    @parcel = get_paginated_records_for(
      :for            => Account,
      :start_index    => params[:start_index],
      :max_results    => params[:max_results],
      :order_by       => params[:order_by],
      :direction      => params[:direction],
      :conditions     => params[:conditions]
      )
      render :response => :GETALL
    rescue Exception => e
      @error = process_exception(e)
      render :response => :error
    end
    
  end
  
  # POST accounts/
  def create
    begin
      @resource = Account.new(params[:account])
      @resource.save!
      render :response => :POST
    rescue Exception => e
      @error = process_exception(e)
      render :response => :error
    end
  end
  
  # DONE!
  # PUT accounts/id
  # PUT accounts/id.xml
  # PUT accounts/id.json
  def update    
    begin
      @resource = Account.find(params[:id])
      @resource.update_attributes!(params[:account])
      render :response => :PUT
    rescue Exception => e
      @error = process_exception(e)
      render :response => :error
    end
  end
  
  # DELETE accounts/id
  # DELETE accounts/id.xml
  # DELETE accounts/id.json
  def destroy

    
    begin
      destroy_item(Account, params[:id], params[:lock_version])
      render :response => :DELETE
    rescue Exception => e
      @error = process_exception(e)
      render :response => :error
    end
  end
  
  protected
  
  def validate_rest_call
    
    if %w{create update}.include? params[:action]
      render :json => report_errors(nil, 'Provide account resource to be created/updated')[0],
        :status => 400 and return false if !params[:account]
      begin
        params[:account] = JSON.parse(params[:account])
        params[:account] = substitute_ids(params[:account])
        check_id_conflict(params[:account], params[:id])
        valid_account?(params[:account], params)
      rescue MadbException => e
        render :json => report_errors(nil, e)[0], :status => e.code and return false
      rescue Exception => e
        render :json => report_errors(nil, e)[0], :status => 400 and return false
      end
      
    end
    
    if params[:action] == 'destroy'
      render :json => report_errors(nil, 'Provide lock_version for update/delete operations')[0],
        :status => 400 and return false if !params[:lock_version]
    end
    
    return true;
  end
  
  def check_ids
    
    if params[:id]
      render :json => report_errors(nil, "Account[#{params[:id]}] does not exists")[0],
        :status => 404 and return false if !Account.exists?(params[:id].to_i)
    end
    
    if params[:account]
      render :json => report_errors(nil,"AccountType[#{params[:account][:account_type_id]}] does not exists")[0], 
        :status => 404 and return false if !AccountType.exists?(params[:account][:account_type_id])
    end
    
    return true
  end
  
  def check_relationships
    begin
      belongs_to_user?(session['user'], 
                    :account => params[:id])
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
