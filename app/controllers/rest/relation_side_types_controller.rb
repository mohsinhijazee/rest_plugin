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
#   This exposes the relation side types as a REST resource
#

class Rest::RelationSideTypesController < ApplicationController
  
  include Rest::RestValidations
  include InstanceProcessor
  
  before_filter :login_required
  
  before_filter :validate_rest_call
  
  before_filter :check_ids
  
  def index
    begin
    @side_types = get_paginated_records_for(
      :for            => RelationSideType,
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
      format.json { render :json => @side_types.to_json(:format => 'json') and return }
    end
  end
  
  def show
    @side_types = RelationSideType.find(params[:id])
    
    respond_to do |format|
      format.json { render :json => @side_types.to_json(:format => 'json') and return }
    end
  end
  

  
  protected
  
  def validate_rest_call
    render  :json => report_errors(nil, "Action '#{params[:action]}' not allowed on relation side types")[0],
            :status => 400 and return false if !%w{show index}.include?(params[:action])
          
    # In all other cases, its ok
    return true;
  end
  
  def check_ids
    
    if params[:id]
      render :json => report_errors(nil, "RelationSideType[#{params[:id]}] does not exists")[0],
        :status => 404 and return false if !RelationSideType.exists?(params[:id])
    end
    
    return true
  end
  
    protected
 # Overriden from LoginSystem in order to render custom message
  def access_denied
    render :json => %Q~{"errors": ["Please login to consume the REST API"]}~, :status => 401
  end
end
