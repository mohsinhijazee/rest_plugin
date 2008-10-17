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
      raise "undefined method new for object mohsin"
      @parcel = get_paginated_records_for(
        :for            => AccountType,
        :start_index    => params[:start_index],
        :max_results    => params[:max_results],
        :order_by       => params[:order_by],
        :direction      => params[:direction],
        :conditions     => params[:conditions]
        )
      respond_to do |wants| 
        wants.html {render :to_xml  => 'GETALL.xml.builder', :layout => false}
        wants.json {render :to_json => 'GETALL.xml.builder'}
        wants.xml  {render :to_xml  => 'GETALL.xml.builder', :layout => false}
        wants.yaml {render :to_yaml => 'GETALL.xml.builder'}
      end    
    rescue Exception => e
      @error = process_exception(e)
      respond_to do| wants|
        wants.html {render :to_xml  => 'error.xml.builder', :layout => false, :status => @error.code }
        wants.json {render :to_json => 'error.xml.builder', :status => @error.code }
        wants.xml  {render :to_xml  => 'error.xml.builder', :layout => false, :status => @error.code }
        wants.yaml {render :to_yaml => 'error.xml.builder', :status => @error.code }
      end
    end
    
    
    
  end
  
  # show will always leave resource in @ resource
  def show
    begin
      @resource = AccountType.find(params[:id])
    
      respond_to do |wants|
        wants.html {render :to_xml  => 'GET.xml.builder', :layout => false}
        wants.xml  {render :to_xml  => 'GET.xml.builder', :layout => false}
        wants.json {render :to_json => 'GET.xml.builder'}
        wants.yaml {render :to_yaml => 'GET.xml.builder'}
      end
      
    rescue Exception => e
      @msg, @code = report_errors(nil, e)
      render :text => @msg, :status => @code and return
    end
    
  end
  
  def create
    @account_type = AccountType.new(params[:account_type])
    
    
    begin
      @account_type.save!
      @msg = 'OK'
      @code = 201
      
      respond_to do |format|
        @msg = [(@@lookup[:AccountType] % [@@base_url, @account_type.id]) + '.json'] if @code == 201
        format.json { render :json => @msg  , :status => @code }
    end
    rescue Exception => e
      @msg, @code = report_errors(@account_type, e)
    end
    
    
    
    
  end
  
  def update
    @account_type = AccountType.find(params[:id])
    
    begin
      @account_type.update_attributes!(params[:account_type])
      @msg = @account_type.to_json(:format => 'json')
      @code = 200
    rescue Exception => e
      @msg, @code = report_errors(@account_type, e)
    end
    
    respond_to do |format|
      format.json { render :json => @msg, :status => @code }
    end
    
  end
  
  def destroy
    begin
      AccountType.destroy(params[:id])
      @msg = 'OK'
      @code = 200
    rescue Exception => e
      @msg, @code = report_errors(nil, e)
    end
    
    respond_to do |format|
      format.json { render :json => @msg, :status => @code }
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
        params[:account_type] = JSON.parse(params[:account_type])
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