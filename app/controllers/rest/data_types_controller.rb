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
#   Proivdes the Dataypes to the external world via REST.
#   Only two operations are possible:
#   
#   GET /datatypes
#   GET /datatypes/:id
#
 


class Rest::DataTypesController < ApplicationController
 include Rest::RestValidations
 include InstanceProcessor
 include Rest::UrlGenerator
 

  before_filter :login_required
  
  before_filter :validate_rest_call
  
  before_filter :check_ids
  
  # GET /datatypes
  def index
    begin
      records = get_paginated_records_for(
      :for            => DataType,
      :start_index    => params[:start_index],
      :max_results     => params[:max_results],
      :order_by       => params[:order_by],
      :direction      => params[:direction],
      :conditions     => params[:conditions]
      )
    rescue Exception => e
      render :text => report_errors(nil, e)[0], :status => 500 and return
    end
    
    respond_to do |format|
      format.json { render :json => records.to_json(:format => 'json'), :status => 200 and return }
    end
  end
  
  # GET /datatypes/:id
  def show
    @datatypes = DataType.find(params[:id].to_i)
    
    respond_to do |format|
      format.json { render :json => @datatypes.to_json(:format => 'json'), :status => 200 and return}
    end
    
  end
  
  protected
  
  def validate_rest_call
    
    render  :json => report_errors(nil, "Action '#{params[:action]}' not allowed on datatypes")[0],
            :status => 400 and return false if !%w{show index}.include?(params[:action])
          
    # In all other cases, its ok
    return true;
  end
  
  def check_ids
    if params[:id]
      render :json => report_errors(nil, "Datatype[#{params[:id]}] does not exists")[0],
        :status => 404 and return false if !DataType.exists?(params[:id].to_i)
    end
    
    # Otherwise, its ok
    return true
  end
  
   protected
 # Overriden from LoginSystem in order to render custom message
  def access_denied
    render :json => %Q~{"errors": ["Please login to consume the REST API"]}~, :status => 401
  end

  
end

