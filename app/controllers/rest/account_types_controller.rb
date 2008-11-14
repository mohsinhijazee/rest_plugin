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
#   This controller exposes the account typees as REST resource
#
#
class Rest::AccountTypesController < Rest::RestController
  
  before_filter :validate_rest_call
  before_filter :check_ids
  
  # Index will always render a resource parcel in @parcel
  def index
    begin
      @parcel = get_paginated_records_for(
        :for            => AccountType,
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
  
  # show will always leave resource in @ resource
  def show
    begin
      @resource = AccountType.find(params[:id])
      render :response => :GET
    rescue Exception => e
      @error = process_exception(e)
      render :response => :error
    end
    
  end
  
  # Create will always create the new resource in @resource
  def create
    begin
      @resource = AccountType.new(params[:account_type])    
      @resource.save!
      render :response => :POST
    rescue Exception => e
      @error = process_exception(e)
      render :response => :error
    end
    
  end
  
    # will always keep the updated resource in @resource.
    # also, will always call update_attributes!
  def update
    begin
      @resource = AccountType.find(params[:id])
      @resource.update_attributes!(params[:account_type])
      render :response => :PUT
    rescue Exception => e
      @error = process_exception(e)
      render :response => :error
    end
  end
  
  def destroy
    begin
      AccountType.destroy(params[:id])
      render :response => :DELETE
    rescue Exception => e
      @error = process_exception(e)
      render :response => :error
    end
    
  end
  
  
  protected
  
  def validate_rest_call
    
    # Creation or updation, check resource provided or not, and
    # parse it.
    if %w{create update}.include?(params[:action])
      render :text => report_errors(nil, 'Provide the account type resource to be created/updated')[0],
        :status => 400 and return false if !params[:account_type]
      
      begin
        params[:account_type] = JSON.parse(params[:account_type])[:account_type]
        params[:account_type] = substitute_ids(params[:account_type])
        check_id_conflict(params[:account_type], params[:id])
      rescue Exception => e
        render :text => report_errors(nil, e)[0], :status => 400 and return false
      end
      
      return true
      
    end
    
    return true;
  end
  
  def check_ids

    if params[:id]
      render :text => report_errors(nil, "AccountType[#{params[:id]}] does not exists")[0],
        :status => 404 and return false if !AccountType.exists?(params[:id])
    end
    
    return true
  end
  
  protected
 # Overriden from LoginSystem in order to render custom message
  def access_denied
    render :json => %Q~{"errors": ["Please login to consume the REST API"]}~, :status => 401
  end
end
  

  
