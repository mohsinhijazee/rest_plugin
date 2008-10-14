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
#   This class provides the REST Interface to the Instances resource
#   It is derived from the EntitiesController so that the functionality 
#   can be resued.
#   
#   
#   01- GET /entities/instances
#   02- GET /instances/:id
#   03- PUT
#
#   
#     
#     
#     [{Field1: [value1, value2], Field2: [value1, value2]}]
#   This way, you can submit multiple records in a single go.
#   BUT NOTE that you can only UPDATE A SINGLE RECORD!
#   
#   NOTES:
#      If the field name contains space, the consumer of the API should replace
#      the spaces with _.
#      
#  NOTES On UPDATE format:
#     User may not want to edit all details
#     If the id is not privded,the detail will be created.   
#  {fieldName: [{id: 10, value: val}, {value: val}]}
#  If the id is not provided in any pair of value/id, then value will be
#  created.
#  
#   update_value and save_value
#   
#   For the GET /entities, you must provide the enitty id in entity param
#   
#   
#
#
#                                 *Creating_Instances*
#                                  ==================
#
#POST this JSON to /entities/4/instances
#
#[
#  {
#   /* Note the multiple values! */
#    "fieldName": ["val1", "val2", "val3"],
#    "fieldAge": [54,78,12]
#  },
#
#  {
#    "fieldName": ["val9", "val8", "val7"],
#    "fieldAge": [15,78,21]
#  },
#]
#
# This will create two instances in the entity 4
#
#                                 *ATTACHMENTS*
#                                 =============
# if any detail value is of S3Attachemnt type, then you should provided the
# file attachment data in a separate request parameter containg text/binary data
# of the file and in the value, mention that parameter. For instance, if you
# have a Person entity with following details:
# Name, Age, Picture
# where picture is of S3Attachment type, then submit following:
# 
# {"Name":["Mohsin"],"Age":[14],"Picture":["picFile1","picFile2"]}
# The picFile1 and picFile2 are request parameters containg the data of the files
# to be uploaded. This should be posted to the /instances with 
# Content-Type of multipart/form-data (or HTML upload forms)
# 
#                              *SAMPLE_cURL_SESSION*
#                              =====================
#                              
# A sample REST session through REST is shown as under: 
# 
#mohsinhijazee@tercel:~$ curl -b cookie -c cookie -F "instances={\"Name\": [\"Mohsin\"], \"Age\": [14], \"Picture\": [\"picFile\"]}" -F"picFile=@notes.txt" -v http://localhost:3000/entities/62/instances.json 
#* About to connect() to localhost port 3000 (#0)
#*   Trying 127.0.0.1... connected
#* Connected to localhost (127.0.0.1) port 3000 (#0)
#> POST /entities/62/instances.json HTTP/1.1
#> User-Agent: curl/7.16.4 (i486-pc-linux-gnu) libcurl/7.16.4 OpenSSL/0.9.8e zlib/1.2.3.3 libidn/1.0
#> Host: localhost:3000
#> Accept: */*
#> Cookie: user_language=en; _madb_session=BAh7CSIJdXNlcm86CVVzZXIKOg1AYWNjb3VudDA6D0B1c2VyX3R5cGUwOhZA%250AYXR0cmlidXRlc19jYWNoZXsAOhBAYXR0cmlidXRlc3sTIglzYWx0IiVmZDk4%250AYTgwMzU1ZDk1OTExMmQzZDllMGFlYmQwOTEyYSIPdXBkYXRlZF9hdCIfMjAw%250AOC0wMS0yOSAxMzoyMzoyNy4yMzc1OTUiEXVzZXJfdHlwZV9pZCIGMSIPYWNj%250Ab3VudF9pZCIGNCIJdXVpZCIlODhmMjliNDM0ZTFkYzRmZDlkMTgxZTllMzQ3%250AOTk3MzMiDWxhc3RuYW1lIgxIaWphemVlIg5maXJzdG5hbWUiC01vaHNpbiIH%250AaWQiBjMiDXZlcmlmaWVkIgYxIhFsb2dnZWRfaW5fYXQwIg1wYXNzd29yZCIl%250AY2I0OWFmZWQ3NzFkMmFjNTY3YzdiNjJlNTkyYzAyM2YiCmxvZ2luIh9tb2hz%250AaW5oaWphemVlQHplcm9wb2ludC5pdCIPY3JlYXRlZF9hdCIfMjAwNy0xMi0y%250ANiAxOTowMjoyNy4yMTMxMTUiCmVtYWlsIh9tb2hzaW5oaWphemVlQHplcm9w%250Ab2ludC5pdDoQQHByZWZlcmVuY2UwIg9saXN0X29yZGVyewAiDnJldHVybi10%250AbyISL2RldGFpbHMuanNvbiIKZmxhc2hJQzonQWN0aW9uQ29udHJvbGxlcjo6%250ARmxhc2g6OkZsYXNoSGFzaHsABjoKQHVzZWR7AA%253D%253D--d0d481a2d1812b694cab0858e0198c4e60939b4b
#> Content-Length: 6261
#> Expect: 100-continue
#> Content-Type: multipart/form-data; boundary=----------------------------1b028b585ac6
#> 
#< HTTP/1.1 200 OK 
#< Cache-Control: private, max-age=0, must-revalidate
#< Connection: Keep-Alive
#< Date: Mon, 31 Mar 2008 11:45:11 GMT
#< Content-Type: text/html; charset=UTF-8
#< Etag: "fdb28c1d72b3180b8a408e7def38e312"
#< Server: WEBrick/1.3.1 (Ruby/1.8.6/2007-06-07)
#< X-Runtime: 0.34531
#< Content-Length: 43
#* Replaced cookie _madb_session="BAh7CSIJdXNlcm86CVVzZXIKOg1AYWNjb3VudDA6D0B1c2VyX3R5cGUwOhZA%250AYXR0cmlidXRlc19jYWNoZXsAOhBAcHJlZmVyZW5jZTA6EEBhdHRyaWJ1dGVz%250AexMiCXNhbHQiJWZkOThhODAzNTVkOTU5MTEyZDNkOWUwYWViZDA5MTJhIhF1%250Ac2VyX3R5cGVfaWQiBjEiD3VwZGF0ZWRfYXQiHzIwMDgtMDEtMjkgMTM6MjM6%250AMjcuMjM3NTk1Ig9hY2NvdW50X2lkIgY0IgdpZCIGMyIOZmlyc3RuYW1lIgtN%250Ab2hzaW4iDWxhc3RuYW1lIgxIaWphemVlIgl1dWlkIiU4OGYyOWI0MzRlMWRj%250ANGZkOWQxODFlOWUzNDc5OTczMyINdmVyaWZpZWQiBjEiCmxvZ2luIh9tb2hz%250AaW5oaWphemVlQHplcm9wb2ludC5pdCINcGFzc3dvcmQiJWNiNDlhZmVkNzcx%250AZDJhYzU2N2M3YjYyZTU5MmMwMjNmIhFsb2dnZWRfaW5fYXQwIgplbWFpbCIf%250AbW9oc2luaGlqYXplZUB6ZXJvcG9pbnQuaXQiD2NyZWF0ZWRfYXQiHzIwMDct%250AMTItMjYgMTk6MDI6MjcuMjEzMTE1Ig9saXN0X29yZGVyewAiDnJldHVybi10%250AbyISL2RldGFpbHMuanNvbiIKZmxhc2hJQzonQWN0aW9uQ29udHJvbGxlcjo6%250ARmxhc2g6OkZsYXNoSGFzaHsABjoKQHVzZWR7AA%253D%253D--986badb959209f5a8590082ad077b98de337bdda" for domain localhost, path /, expire 0
#< Set-Cookie: _madb_session=BAh7CSIJdXNlcm86CVVzZXIKOg1AYWNjb3VudDA6D0B1c2VyX3R5cGUwOhZA%250AYXR0cmlidXRlc19jYWNoZXsAOhBAcHJlZmVyZW5jZTA6EEBhdHRyaWJ1dGVz%250AexMiCXNhbHQiJWZkOThhODAzNTVkOTU5MTEyZDNkOWUwYWViZDA5MTJhIhF1%250Ac2VyX3R5cGVfaWQiBjEiD3VwZGF0ZWRfYXQiHzIwMDgtMDEtMjkgMTM6MjM6%250AMjcuMjM3NTk1Ig9hY2NvdW50X2lkIgY0IgdpZCIGMyIOZmlyc3RuYW1lIgtN%250Ab2hzaW4iDWxhc3RuYW1lIgxIaWphemVlIgl1dWlkIiU4OGYyOWI0MzRlMWRj%250ANGZkOWQxODFlOWUzNDc5OTczMyINdmVyaWZpZWQiBjEiCmxvZ2luIh9tb2hz%250AaW5oaWphemVlQHplcm9wb2ludC5pdCINcGFzc3dvcmQiJWNiNDlhZmVkNzcx%250AZDJhYzU2N2M3YjYyZTU5MmMwMjNmIhFsb2dnZWRfaW5fYXQwIgplbWFpbCIf%250AbW9oc2luaGlqYXplZUB6ZXJvcG9pbnQuaXQiD2NyZWF0ZWRfYXQiHzIwMDct%250AMTItMjYgMTk6MDI6MjcuMjEzMTE1Ig9saXN0X29yZGVyewAiDnJldHVybi10%250AbyISL2RldGFpbHMuanNvbiIKZmxhc2hJQzonQWN0aW9uQ29udHJvbGxlcjo6%250ARmxhc2g6OkZsYXNoSGFzaHsABjoKQHVzZWR7AA%253D%253D--986badb959209f5a8590082ad077b98de337bdda; path=/
#< 
#* Connection #0 to host localhost left intact
#* Closing connection #0
#["http://localhost:3000/instances/33.json"]
#

#
#                           *Updating_an_Instance*
#                            ===================
#NOTE: You can only update a single instance!
#
#PUT this JSON to /instances/2
#
#{
#  "fieldName": [
#                {"id": 21, "value": "new val"}, 
#                {"id": 22, "value": "myval"}, 
#                /*WITHOUT ID! WILL BE CREATED!*/
#                {"value": "new val"} 
#               ],
#
#  "fieldAge": [
#                {"id": 11, "value": 41}, 
#                {"id": 12, "value": 49}, 
#                /*WITHOUT ID! WILL BE CREATED!*/
#                {"value": 202} 
#               ],
#
#}
#
#This will update the values of details of the given instance whose ids
#are provided and will create the values if the id is not given.



require 'json'
class Rest::InstancesController < ApplicationController
  
  include Rest::RestValidations
  include InstanceProcessor  
  
  
  before_filter :login_required
  
  before_filter :validate_rest_call
  
  before_filter :check_ids
  
  before_filter :check_relationships
  
  
  
  # *Description*
  #   Gets all the instances of the given entity
  #   by:
  #   
  #   * GET /entities/instances
  #   * GET /databases/entities/instances
  #
  def index
    # Get the records for the entity.
    begin
      records = get_paginated_records_for(
      :for => Instance,
      :entity => params[:entity_id],
      :start_index => params[:start_index],
      :max_results => params[:max_results],
      :order_by => params[:order_by],
      :direction => params[:direction],
      :conditions => params[:conditions]
      )
    rescue Exception => e
      render :text => report_errors(nil, e)[0], :status => 500 and return
    end
    
    respond_to do |format|
      format.json { render :json => records.to_json(:format => 'json'), :status => 200 and return}
    end
    
  end
  
  # *Description*
  #   Gets a particulalr instance with either:
  #   GET /instance/:id
  #   GET /entities/instances/:id
  #   GET /databases/entities/instances/:id
  #
  def show
     begin
       @instance = Instance.find(params[:id])
     rescue Exception => e
       render :json => report_errors(nil, e)[0], :status => 400 and return
     end
     
     respond_to do |format|
      format.json { render :json => @instance.to_json(:format => 'json') and return }
    end
  end
  
  
  def create
    instances = []
    urls = []
    
    begin
      Instance.transaction do
        instances = save_instances(params[:entity_id], params[:instance])
      end
      instances.each do |instance|
        urls << (@@lookup[:Instance] % [@@base_url, instance.id]) + '.json'
      end
      @msg = urls.to_json
      @code = 201
    rescue Exception => e
      puts e.backtrace
      @msg, @code = report_errors(nil, e)
    end
    
    
    
    
    
    respond_to do |format|
      format.json { render :json => @msg, :status => @code and return}
    end
    
  end
  
  def update
    instance = nil
    begin
      Instance.transaction do
        instance = update_instance(params[:id], params[:instance])
      end
      @code = 200
    rescue ActiveRecord::StaleObjectError => e
      puts e.backtrace
      @msg = report_errors(nil, e)[0]
      @code = 409
    rescue MadbException => e
      puts e.backtrace
      @msg = report_errors(nil, e)[0]
      @code = e.code
    rescue Exception => e
      puts e.backtrace
      @msg, @code =  report_errors(nil, e)
    end
    
    @msg = instance.to_json(:format => 'json') if @code == 200
    
    respond_to do |format|
      format.json { render :json => @msg, :status => @code}
    end
    
  end
  
  
  
  # *Description*
  #   Deletes an instance with either:
  #   DELETE /instances/:id
  #   DELETE /entities/:entity_id/instances/:id
  #   DELETE /databases/:database_id/entities/:entity_id/instances/:id
  #
  def destroy
    
    begin
      destroy_item(Instance, params[:id], params[:lock_version])
      @msg = 'OK'
      @code = 200
    rescue ActiveRecord::StaleObjectError => e
      @msg = report_errors(nil, e)[0]
      @code = 409
    rescue Exception => e
      puts e.backtrace
      @msg = report_errors(nil, e)[0]
      @code = 500
    end
    
    respond_to do |format|
      format.json { render :json => @msg, :status => @code and return}
    end
    
  end
  
  protected
  
  # *Description*
  #   This validates the incoming REST call
  def validate_rest_call
  
    # if the instance resource is provided, parse it
    if params[:instance]
      begin 
        params[:instance] = JSON.parse(params[:instance])
        params[:instance] = substitute_ids(params[:instance])        
        params[:instance] = [params[:instance]] if params[:instance].is_a?(Hash) and params[:action] == 'create'
        check_id_conflict_for_instance(params[:instance], params[:id])
        valid_instances?(params[:instance], params)
        params[:entity_id] = params[:instance][0].delete('entity_id') if !params[:entity_id] and params[:action] == 'create'
        return false if !check_ids
      rescue MadbException => e
        #puts e.backtrace
        render :json => report_errors(nil, e)[0], :status => e.code and return false
      rescue Exception => e
        #puts e.backtrace
        render :json => report_errors(nil, e)[0], :status => 400 and return false
      end
    end
  
    # GET /instances is not allowed!
    if params[:action] == 'index'
      render :json => report_errors(nil, 'GET /instances is not allowed, use GET /entities/:entity_id/instances')[0],
        :status => 400 and return false if !params[:entity_id]
    end
    
    # POST /instances is not allowed!
    # POST /entities/:entity_id/instances should be used.
    if params[:action] == 'create'
       render :json => report_errors(nil, 'Provide the instances to be created in instances parameter of request')[0],
        :status => 400 and return false if !params[:instance]
      
      
#      render :json => report_errors(nil, 'POST /instances is not allowed, use POST /entities/:entity_id/instances')[0],
#        :status => 400 and return false if !params[:entity_id]
      
      
#      begin
#        valid_instances?(params[:entity_id], params[:instance])
#      rescue Exception => e
#          render :json => report_errors(nil, e)[0], :status => 400 and return false
#      end

      # If any detail is missing, notify the user and return
#      render :json => report_errors(nil, "Details Missing: [#{missing_details.sort.join(', ')}]")[0], 
#        :status => 400 and return false if missing_details.length > 0  
    end
    
    if params[:action] == 'update'
      render :json => report_errors(nil, 'Provide the instances to be created in instances parameter of request')[0],
        :status => 400 and return false if !params[:instance]
      
#      # Find the instance
#      i = nil
#      begin
#        i = Instance.find(params[:id])
#        params[:entity_id] = i.entity_id
#      rescue Exception => e
#        render :json => report_errors(nil, "Instance[#{params[:id]}] does not exists")[0],
#          :status => 404 and return false
#      end
#      
#      begin
#        valid_instances?(params[:entity_id], params[:instance])
#      rescue Exception => e
#          render :json => report_errors(nil, e)[0], :status => 400 and return false
#      end
#      
#      
#      # Validate the instance resource
#      bad_details = valid_instance_for_update?(i.entity_id, params[:instance])
#      
#      render :json => report_errors(nil, "Details do not belong to Entity: [#{bad_details.join(', ')}]")[0],
#        :status => 400 and return false if bad_details.length > 0
    end
    
    if params[:action] == 'destroy'
      render :json => report_errors(nil, 'Provide lock_version for update/delete operations')[0],
        :status => 400 and return false if !params[:lock_version]
    end
    
    # In all other cases, its ok
    return true
    
  end
  
  
  #FIXME: Add proper validation of ids
  #FIXME: Add the validation of udpation instances
  def check_ids
    
    if params[:entity_id]
      render :json => report_errors(nil, "Entity[#{params[:entity_id]}] does not exists")[0],
        :status => 404 and return false if !Entity.exists?(params[:entity_id])
    end
    
    if params[:id]
      render :json => report_errors(nil, "Instance[#{params[:id]}] does not exists")[0],
        :status => 404 and return false if !Instance.exists?(params[:id])
    end
    
    return true;
  end
  
  def check_relationships
    if params[:entity_id] and params[:id]
      render :json => report_errors(nil, "Instance[#{params[:id]}] does not belong to Entity[#{params[:entity_id]}]")[0],
        :status => 400 and return false if !related_to_each_other?(:entity => params[:entity_id], :instance => params[:id])
    end
    
    begin
      belongs_to_user?(session['user'], 
          :entity => params[:entity_id],
          :instance => params[:id]
                    )
    rescue MadbException => e
      render :json => report_errors(nil, e)[0], :status => 400 and return false
    end
    
    return true
  end
  
  
  def check_id_conflict_for_instance(instances, id)
    if instances.is_a?(Array)
      instances.each do |instance|
        check_id_conflict(instance, id)
      end
    else
      check_id_conflict(instances, id)
    end
  end
  
  protected
 # Overriden from LoginSystem in order to render custom message
  def access_denied
    render :json => %Q~{"errors": ["Please login to consume the REST API"]}~, :status => 401
  end

end

