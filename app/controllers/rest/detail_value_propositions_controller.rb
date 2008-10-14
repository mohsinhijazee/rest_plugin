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
#   Exposes the detail value proposition
#
#
#  params[:detail_value_proposition][detail_id]
#  params[:detail_value_proposition][:values]
# {"detail_id": 45, "value": ["Married", "Single", "Divorced", "Disclosed"]}
#
# FOR UPDATE
#  {value: 'value'}
#  NOTE:
# In case of nested calls, the detail_id provided in the path is taken if
# resource does not mention it.
class Rest::DetailValuePropositionsController < ApplicationController

  include Rest::RestValidations
  include InstanceProcessor
  include Rest::UrlGenerator
  
  before_filter :login_required
  before_filter :validate_rest_call
  before_filter :check_ids
  before_filter :check_relationships
  
  
  def index
    begin
      params[:conditions] = add_condition(params[:conditions], "detail_id=#{params[:detail_id]}", :and)
      records = get_paginated_records_for(
      :for            => DetailValueProposition,
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
      format.json { render :json => records.to_json(:format => 'json') and return}
    end
  end
  
  def show
    @props = DetailValueProposition.find(params[:id])
    
    respond_to do |format|
      format.json { render :json => @props.to_json(:format => 'json') and return}
    end
  end
  
  def create
    urls = nil
    begin
      urls = create_propostions(params[:detail_value_proposition][:detail_id],params[:detail_value_proposition][:value])
      #@msg = urls.to_json.gsub('\\', '')
      @code = 201
    rescue Exception => e
      @msg, @code = report_errors(nil, e)
    end
    
    respond_to do |format|
      format.json do
        if @code == 201
          urls.collect! { |item|  item + '.json'}
          @msg = urls.to_json
        end
        render :json => @msg, :status => @code   
      end
    end
  end
  
  def update
    @prop = DetailValueProposition.find(params[:id])

    begin    
      if @prop.update_attributes(
          :value => params[:detail_value_proposition][:value],
          :lock_version => params[:detail_value_proposition][:lock_version]
        )
        @msg = @prop.to_json(:format => 'json')
        @code = 200
      else
        @msg, @code= report_errors(@prop, nil)
      end
    rescue ActiveRecord::StaleObjectError => e
      @msg = report_errors(@prop, e)[0]
      @code = 409
    rescue Exception => e
      @msg = report_errors(@prop, e)[0]
      @code = 400
    end
    
    respond_to do |format|
      format.json { render :json => @msg, :status => @code }
    end
    
  end
  
  def destroy
    begin
      destroy_item(DetailValueProposition, params[:id], params[:lock_version])
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
      format.json { render :json => @msg, :status => @code}
    end
  end
  
  
    
    
  
  protected
  
  def validate_rest_call
    
    if params[:detail_value_proposition]
    # Parase the JSON
      begin
        params[:detail_value_proposition] = JSON.parse(params[:detail_value_proposition])
        params[:detail_value_proposition] = substitute_ids(params[:detail_value_proposition])
        check_id_conflict(params[:detail_value_proposition], params[:id])
        valid_proposition?(params[:detail_value_proposition], params)
      rescue MadbException => e
        render :json => report_errors(nil, e)[0], :status => e.code and return false
      rescue Exception => e
        render :json => report_errors(nil, e)[0], :status => 400 and return false
      end
    end
      
    
    if params[:action] == 'index'
      render :json => report_errors(nil, 'GET /propositions is not allowed. Use GET /details/:detail_id/propositions instead')[0],
        :status => 400 and return false if !params[:detail_id]
    end
    
    if %w{create update}.include? params[:action]
      render :json => report_errors(nil, 'Provide propositions resource to be created/updated')[0],
        :status => 400 and return false if !params[:detail_value_proposition]
      
      
#      if params[:action] == 'create'
#        # Make the single value in an array.
#        if params[:detail_value_proposition][:values]
#          if !params[:detail_value_proposition][:values].is_a? Array
#            params[:detail_value_proposition][:values] [params[:detail_value_proposition][:values]] 
#          end
#        end
#        # if the detail id is not provided but its a nested call
#        if params[:detail_id] #and !params[:detail_value_proposition][:detail_id]
#          params[:detail_value_proposition][:detail_id] = params[:detail_id] 
#        elsif !params[:detail_id] and !params[:detail_value_proposition][:detail_id]
#          render :json => report_errors(nil, 'Provide the detail id as detail_id in propositions resource or make a nested call')[0],
#            :status => 400 and return false
#        end
#      end
#       
    end
    
    if params[:action] == 'destroy'
      render :json => report_errors(nil, 'Provide lock_version for update/delete operations')[0],
        :status => 400 and return false if !params[:lock_version]
    end
    
    return true
  end
  
  def check_ids
    
    if params[:id]
      render :json => report_errors(nil,"DetailValueProposition[#{params[:id]}] does not exists")[0],
        :status => 404 and return false if !DetailValueProposition.exists?(params[:id])
    end
    
    if params[:detail_id]
      render :json => report_errors(nil,"Detail[#{params[:detail_id]}] does not exists")[0],
        :status => 404 and return false if !Detail.exists?(params[:detail_id])
      
      render :json => report_errors(nil,"Detail[#{params[:detail_id]}] is not of type madb_choose_in_list")[0],
        :status => 400 and return false if Detail.find(params[:detail_id]).data_type.name != 'madb_choose_in_list'
    end
    
    if params[:detail_value_proposition]
      if params[:detail_value_proposition][:detail_id]
        render :json => report_errors(nil,"Detail[#{params[:detail_value_proposition][:detail_id]}] does not exists")[0],
          :status => 404 and return false if !Detail.exists?(params[:detail_value_proposition][:detail_id])

        render :json => report_errors(nil,"Detail[#{params[:detail_value_proposition][:detail_id]}] is not of type madb_choose_in_list")[0],
          :status => 400 and return false if Detail.find(params[:detail_value_proposition][:detail_id]).data_type.name != 'madb_choose_in_list'
      end
    end
    
    
    return true
  end
  
  def check_relationships
    
    if params[:detail_id] and params[:id]
      render :json => report_errors(nil, "DetailValueProposition[#{params[:id]}] does not belong to Detail[#{params[:detail_id]}]")[0],
        :status => 400 and return false if !related_to_each_other?(:detail => params[:detail_id], 
        :detail_value_proposition => params[:id])
    end
    
    begin
      belongs_to_user?(session['user'], 
                    :detail => params[:detail_id],
                    :detail_value_proposition => params[:id])
    rescue MadbException => e
      render :json => report_errors(nil, e)[0], :status => 400 and return false
    end
    
    
    return true
  end
  
  #FIXME: Should be moved elsewhere?
  def create_propostions(detail_id, propositions)
    urls = []
    
    DetailValueProposition.transaction do 
      propositions.each do |prop|
        p = DetailValueProposition.new
        p.detail_id = detail_id
        p.value = prop
        p.save!
        #ids.push(p.id)
        urls.push(@@lookup[:DetailValueProposition] % [@@base_url, p.id]) 
      end
    end
    return urls
  end
  
  protected
 # Overriden from LoginSystem in order to render custom message
  def access_denied
    render :json => %Q~{"errors": ["Please login to consume the REST API"]}~, :status => 401
  end
  
end
