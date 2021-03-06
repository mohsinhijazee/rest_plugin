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
#   This class epxoses the user types as resoruce.
#
class Rest::UserTypesController < Rest::RestController

  before_filter :validate_rest_call
  
  before_filter :check_ids
  
  
  def index
    begin
      @parcel = get_paginated_records_for(
      :for            => UserType,
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
  
  def show
    begin
      @resource = UserType.find(params[:id])
      render :response => :GET
    rescue Exception => e
      @error = process_exception(e)
      render :response => :error
    end
    
  end
  
  protected
  
  def check_ids
    if params[:id]
      render :json => report_errors(nil, "UserType[#{params[:id]}] does not exists")[0],
        :status => 404 and return false if !UserType.exists?(params[:id])
    end
  end
  
  def validate_rest_call
    
    render  :json => report_errors(nil, "Action '#{params[:action]}' not allowed on user types")[0],
            :status => 400 and return false if !%w{show index}.include?(params[:action])
          
    # In all other cases, its ok
    return true;
  end
    
    protected
 # Overriden from LoginSystem in order to render custom message
  def access_denied
    render :json => %Q~{"errors": ["Please login to consume the REST API"]}~, :status => 401
  end
  
end
