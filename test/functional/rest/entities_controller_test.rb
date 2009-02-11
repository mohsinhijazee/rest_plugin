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

require File.dirname(__FILE__) + '/../../test_helper'
require 'rest/entities_controller'

# 
# assert_response status_code
# assert_redirect
# assert_redirect_to
# Re-raise errors caught by the controller.
class Rest::EntitiesController; def rescue_action(e) raise e end; end

class EntitiesControllerTest < Test::Unit::TestCase
  
  fixtures  :account_types,
            :account_type_values,
            :accounts, 
            :databases, 
            :data_types, 
            :detail_status, 
            :details, 
            :detail_value_propositions, 
            :entities, 
            :entities2details, 
            :relation_side_types, 
            :relations, 
            :instances, 
            :detail_values, 
            :integer_detail_values, 
            :date_detail_values, 
            :ddl_detail_values, 
            :links, 
            :user_types, 
            :users
         
  def setup
    @controller   = Rest::EntitiesController.new
    @request      = ActionController::TestRequest.new
    @response      = ActionController::TestResponse.new
    
    @db1_admin_user_id = 2
    @db1_normal_user_id = 1000001
    @db2_admin_user_id = 1000003
    
  end
  
  def test_without_login
    #FIXME: Would be rewritten after REST Auth
    assert true
#    id = 1
#    get :show, {:format => 'json', :id => id}, {'user' => nil}
#    assert_response 401
#    json = %Q~{"errors": ["Please login to consume the REST API"]}~
#    assert_equal json, @response.body  
  end
  
  def test_accessing_without_adminstrative_rights
    #FIXME: This validation has yet to be dependent upon REST Auth
#    user  = User.find @db1_normal_user_id
#    parent = :database_id
#    parent_id = 6
#    id = 100
#    
#    get :index, {:format => 'json', parent => parent_id}, {'user' => user}
#    assert_response 200
#    
#    get :show, {:format => 'json', :id => id}, {'user' => user}
#    assert_response 200
#    
#    resource_name = :entity
#    resource = %Q~{"name": "asf"}~
#    msg = {:errors => ['This REST call needs administrative rights']}
#    
#    post :create, {:format => 'json', :database_id => 6, resource_name => resource}, {'user' => user}
#    #assert_equal '', @response.body
#    assert_response 403
#    assert_equal msg.to_json, @response.body
#    
#    put :update, {:format => 'json', resource_name => resource}, {'user' => user}
#    assert_response 403
#    assert_equal msg.to_json, @response.body
#    
#    delete :destroy, {:format => 'json', :id => 45}, {'user' => user}
#    assert_response 403
    #assert_equal '', @response.body
    
  end
  
#  def test_accessing_irrelevant_item
#    res_id = 3
#    res_name = 'Account'
#    user = User.find @db1_admin_user_id
#    json = {:errors =>["#{res_name}[#{res_id}] does not belong to User[#{user.id}] (\"#{user.login}\")"]}.to_json
#    get :show, {:format => 'json', :id => 3}, {'user' => user}
#    assert_equal json, @response.body
#  end
  
  # *Description*
  #   This tests the following URLs:
  #   GET /databases
  
  def test_get_all
    # CASE 01: GET /entities 
    # CASE 02: GET /databases/:database_id/entities with all ok
    # CASE 03: GET /databases/:database_id/entities with wrong dataabse id
    user = User.find_by_id(@db1_admin_user_id)
    
    
    ######################################################################
    #                             CASE 01
    # GET /entities.json
    #
    #######################################################################
    #Emulate the wrong call
    # GET /entities
    get :index, {:format => :json}, {'user' => user}
    
    assert_response 400
    
    json = {:errors => ['GET /entities is not allowed, use GET /entities?database=id instead.']}.to_json
    assert_equal json, @response.body, "Response differs!"
    
    
    ######################################################################
    #                          CASE 02                                     
    # GET /databases/:database_id/entities.json
    # with correct database id
    #######################################################################
    db = 6
    json = Entity.find(:all, :conditions => ["database_id = ?", db])
    get :index, {:database_id => db, :format => 'json'}, {'user' => user}
    assert_response :success
    result = JSON.parse(@response.body)
    assert_equal json.length, result['resources'].length, "JSON not equal!"
    
    
    ######################################################################
    #                         CASE 03
    # GET /databases/:database_id/entities.json
    # with incorrect database id
    #######################################################################
    db = 62415
    json = {:errors => ["Database[#{db}] does not exists."]}.to_json
    get :index, {:database_id => db, :format => 'json'}, {'user' => user}
    #assert_response :success
    assert_equal json, @response.body, "JSON not equal!"
    
  end
  
  def test_get_all_with_pagination
    # CASE 01: Mention of start_index and max_results
    # CASE 02: Mention of Order by with direction
    # CASE 03: Mention of Order by without direction
    # CASE 04: Mention a condition also
    user = User.find_by_id(@db1_admin_user_id)
    
    parent_resource = :database_id
    parent_id = 6
    start_index = 10
    max_results = 10
    order_by = 'name'
    direction = 'DESC'
    table_name = 'entities'
    conditions = 'database_id=6'
    total_records = Entity.count_by_sql "SELECT COUNT(*) FROM  #{table_name} WHERE #{conditions}"
    conditions = 'id=100'
    #########################################################
    #                        CASE 01
    #        Mention of start_index and max_results
    #########################################################
    get :index, {
      parent_resource => parent_id,
      :format => 'json', 
      :start_index => start_index, 
      :max_results => max_results},
      {'user' => user}
    
    #assert_equal '', @response.body
    assert_response 200
    result = @response.body

    result = JSON.parse(result)

    assert_equal 10, result['resources'].length
    assert_equal total_records, result['total_resources']
    
    
    
    #########################################################
    #                        CASE 02
    #        Mention of order by with direction
    #########################################################
    get :index, {
      parent_resource => parent_id,
      :format => 'json', 
      :start_index => start_index, 
      :max_results => max_results,
      :order_by => order_by,
      :direction => direction
    },
      {'user' => user}
    
    #assert_equal '', @response.body
    assert_response 200
    result = @response.body

    result = JSON.parse(result)

    assert_equal 10, result['resources'].length
    assert_equal 'desc', result['direction']
    
    #########################################################
    #                        CASE 03
    #        Mention of order by with direction
    #########################################################
    get :index, {
      parent_resource => parent_id,
      :format => 'json', 
      :start_index => start_index, 
      :max_results => max_results,
      :order_by => order_by,
      #:direction => direction
    },
      {'user' => user}
    
    #assert_equal '', @response.body
    assert_response 200
    result = @response.body

    result = JSON.parse(result)

    assert_equal max_results, result['resources'].length
    assert_equal 'asc', result['direction']
    
    #########################################################
    #                        CASE 04
    #        Mention of order by with direction
    #########################################################
    get :index, {
      parent_resource => parent_id,
      :format => 'json', 
      :start_index => start_index, 
      :max_results => max_results,
      :order_by => order_by,
      :conditions => conditions
    },
      {'user' => user}
    
    #assert_equal '', @response.body
    assert_response 200
    result = @response.body

    result = JSON.parse(result)

    assert_equal 1, result['resources'].length
    assert_equal 'asc', result['direction']
    
    
  end
  
  def test_get_single
    # CASE 01: GET /entities/:id
    # CASE 02: GET /entities/:id with wrong id
    # CASE 03: GET /databases/:database_id/entities/:id with all ok
    # CASE 04: GET /databases/:database_id/entities/:id with wrong entity id
    # CASE 05: GET /databases/:database_id/entities/:id with wrong databse
    user = User.find(@db1_admin_user_id)
    
    entity = 14
    ######################################################################
    #                        CASE 01
    # GET /entities/:id
    # with all correct
    #######################################################################
    model = Entity.find(entity)
    get :show, {:format => 'json', 'id' => entity}, {'user' => user}
    
    assert_response 200
    assert_similar model, @response.body
    
    
    entity = 1896
    ######################################################################
    #                          CASE 02                                          
    # GET /entities/:id
    # with incorrect id
    #######################################################################
    json = {:errors => ["Entity[#{entity}] does not exists."]}.to_json
    get :show, {:format => 'json', 'id' => entity}, {'user' => user}
    
    assert_response 404
    
    assert_equal json, @response.body, "JSON Not equal!"
    
    db = 8
    entity = 52
    ######################################################################
    #                          CASE 03                                          
    # GET databases/:database_id/entities/:id
    # with all correct ids.
    #######################################################################
    model = Entity.find(:first, :conditions => ["database_id=?", db])
    get :show, {:format => 'json', :database_id => db, :id => entity}, {'user' => user}
    
    assert_response 200
    assert_similar model , @response.body
    
    
    db = 8
    entity = 1952
    ######################################################################
    #                            CASE 04                                                              
    # GET databases/:database_id/entities/:id
    # with l incorrect entity id
    #######################################################################
    json = {:errors => ["Entity[#{entity}] does not exists."]}.to_json
    get :show, {:format => 'json', :database_id => db, :id => entity}, {'user' => user}
    
    assert_response 404
    
    assert_equal json , @response.body, "JSON Not equal!"
    
    db = 1118
    entity = 52
    ######################################################################
    #                            CASE 05                                                              
    # GET databases/:database_id/entities/:id
    # with incorrect database id
    #######################################################################
    json = {:errors => ["Database[#{db}] does not exists."]}.to_json
    get :show, {:format => 'json', :database_id => db, :id => entity}, {'user' => user}
    
    assert_response 404
    
    assert_equal json , @response.body, "JSON Not equal!"
    
    db = 8
    entity = 12
    ######################################################################
    #                                                                    
    # GET databases/:database_id/entities/:id
    # entity and database do not relate to each other
    #######################################################################
    json = {:errors => ["Entity[#{entity}] does not belong to Database[#{db}]"]}.to_json
    get :show, {:format => 'json', :database_id => db, :id => entity}, {'user' => user}
    
    assert_response 400
    
    assert_equal json , @response.body, "JSON Not equal!"
    
    
    
    
  end
  
  def test_put
    # CASE 01: PUT /entities/:id with all ok
    # CASE 02: PUT /entities/:id with wrong id
    # CASE 03: PUT /entities/:id with entity data missing
    # CASE 04: PUT /databases/:database_id/entities/:id with all ok
    # CASE 05: PUT /databases/:database_id/entities/:id with wrong entity
    # CASE 06: PUT /databases/:database_id/entities/:id with wrong database
    user = User.find(@db1_admin_user_id)
    
    entity = 100
    data = {'name' => 'new_name'}
    data[:lock_version] = Entity.find(entity).lock_version
    ######################################################################
    #                         CASE 01
    # PUT /entities/:id
    # with all correct
    #######################################################################
    put :update, {:format => 'json', :id => entity, 
                 :entity => data.to_json },
                 {'user' => user}
    
    model = Entity.find(entity) 
    assert_response :success    
    assert_similar model, @response.body
    
    
    
    
    entity = 1830
    data = {'name' => 'new_name'}
    data[:lock_version] = 465
    ######################################################################
    #                     CASE 02
    # PUT /entities/:id
    # with incorrect entity id
    #######################################################################
    put :update, {:format => 'json', :id => entity, 
                 :entity => data.to_json },
                 {'user' => user}
    
    json = {:errors => ["Entity[#{entity}] does not exists."]}.to_json
    
    assert_response 404
        
    assert_equal json, @response.body, 'JSON NOT EQUAL!'
    
    entity = 100
    data = {'name' => 'new_name'}
    data[:lock_version] = 798
    ######################################################################
    #                         CASE 03
    # PUT /entities/:id
    # with with entity param missing
    #######################################################################
    put :update, {:format => 'json', :id => entity, 
                 :entity => nil },
                 {'user' => user}
    
    json = {:errors => ['Provide the entity resource for create/update']}.to_json
    
    assert_response 400
    assert_equal json, @response.body, 'JSON NOT EQUAL!'
    
    
    db = 8
    entity = 52
    data = {'name' => 'new_name'}
    data[:lock_version] = Entity.find(entity).lock_version
    ######################################################################
    #                      CASE 04                                                     
    # PUT databases/:database_id/entities/:id
    # with all correct
    #######################################################################
    put :update, {:format => 'json', 
                  :id => entity, 
                  :database_id => db,
                 :entity => data.to_json},
                 {'user' => user}
    
    model = Entity.find(entity)  
    assert_response :success
    assert_similar model, @response.body
    
    
    db = 8
    entity = 1952
    data = {'name' => 'new_name'}
    data[:lock_version] = 4654
    ######################################################################
    #                          CASE 05                                                                
    # PUT databases/:database_id/entities/:id
    # with entity id incorrect
    #######################################################################
    put :update, {:format => 'json', 
                  :id => entity, 
                  :database_id => db,
                 :entity => data.to_json},
                 {'user' => user}
    
    json = {:errors => ["Entity[#{entity}] does not exists."]}.to_json
    
    assert_response 404
        
    assert_equal json, @response.body, 'JSON NOT EQUAL!'
    
    db = 118
    entity = 52
    data = {'name' => 'new_name'}
    data[:lock_version] = 779
    ######################################################################
    #                         CASE 06                                                      
    # PUT databases/:database_id/entities/:id
    # with database id incorrect
    #######################################################################
    put :update, {:format => 'json', 
                  :id => entity, 
                  :database_id => db,
                  :entity => data.to_json},
                 {'user' => user}
    
    json = {:errors => ["Database[#{db}] does not exists."]}.to_json
    
    assert_response 404
        
    assert_equal json, @response.body, 'JSON NOT EQUAL!'
    
    db = 8
    entity = 30
    data = {'name' => 'new_name'}
    data[:lock_version] = 79879
    ######################################################################
    #                       CASE 07                                                               
    # PUT databases/:database_id/entities/:id
    # with database and entity unrelated.
    #######################################################################
    put :update, {:format => 'json', 
                  :id => entity, 
                  :database_id => db,
                  :entity => data.to_json},
                 {'user' => user}
    
    json = {:errors => ["Entity[#{entity}] does not belong to Database[#{db}]"]}.to_json
    
    assert_response 400
        
    assert_equal json, @response.body, 'JSON NOT EQUAL!'
    
  end 
  
  def test_put_without_lock_version
    
    user = User.find(@db1_admin_user_id)
    
    entity = 30
    data = {'name' => 'new_name'}
    #data[:lock_version] = 798
    
    put :update, {:format => 'json', :id => entity, 
                 :entity => data.to_json },
                 {'user' => user}
    
    json = {:errors => ["Provide lock_version for update/delete operations"]}.to_json    
    assert_response 400
    assert_equal json, @response.body, 'JSON NOT EQUAL!'
    
    
  end
  
  def test_get_and_put
    user = User.find_by_id @db1_admin_user_id
    
    id = 100
    res_name = 'entity'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource = JSON.parse(@response.body)
    
    
    resource['name'] = 'GET AND PUT TEST'
    
    put :update, {:format => 'json', :id => id, res_name => resource.to_json}, {'user' => user}
    #assert_equal '', @response.body
    
    assert_response 200
    new_val = JSON.parse(@response.body)
    assert_equal resource['name'], new_val['name']    
    
  end
  
  def test_get_and_put_conflict
    user = User.find_by_id @db1_admin_user_id
    
    id = 100
    res_id = 78
    res_name = 'entity'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource = JSON.parse(@response.body)
    
    resource['name'] = 'GET AND PUT TEST'
    resource['url'] = 'http://localhost:300/entities/' + res_id.to_s + '.json'
    
    json = {:errors => ["Requested ID is #{id} and ID in resource is #{res_id}. Are you dispatching your resource at the right location?"]}.to_json
    put :update, {:format => 'json', :id => id, res_name => resource.to_json}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
  end
  
  def test_get_and_put_version_conflict
    user = User.find_by_id @db1_admin_user_id
    
    id = 100
    res_name = 'entity'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource1 = JSON.parse(@response.body)
    
    resource1['name'] = 'GET AND PUT TEST'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource2 = JSON.parse(@response.body)
    
    resource2['name'] = 'GET AND PUT TEST8'
    
    put :update, {:format => 'json', :id => id, res_name => resource1.to_json}, {'user' => user}
    #assert_equal '', @response.body
    assert_response 200
    new_val = JSON.parse(@response.body)
    assert_equal resource1['name'], new_val['name']    
    
    message = "Attempted to update a stale object"
    put :update, {:format => 'json', :id => id, res_name => resource2.to_json}, {'user' => user}
    assert_response 409

    assert_equal message, JSON.parse(@response.body)['message']

    
    
    
    
  end
  
  
  def test_post
    # CASE 01: POST /entities with complete entity resource
    # CASE 02: POST /entities with skipping database id at all
    # CASE 03: POST /databases/:database_id/entities with all ok
    # CASE 04: POST /databases/:database_id/entities with wrong database id
    user = User.find(@db1_admin_user_id)
    
    db = 8
    data = { :name => 'test_entity',
                          :database_url => "http://localhost:3000/databases/#{db}.json"
                        }
    ######################################################################
    #                       CASE 01                                             
    # POST /entities
    # creating an entity
    #######################################################################
    pre_count = Entity.count
    
    post :create , {  :format => 'json',
                      :entity => data.to_json },
                    {'user' => user}
                  
    post_count = Entity.count
    assert_response 201
    assert_equal 1, post_count - pre_count
    #assert_equal '', @response.body
    

    
    db = 198
    data = { :name => 'test_entity'}
    ######################################################################
    #                                CASE 02                                    
    # POST /entities
    # creating an entity while the database parameter is altogather skipped
    # and not proivded either through database_id or database
    #######################################################################
    pre_count = Entity.count
    
    post :create , {  :format => 'json',
                      :entity => 
                        data.to_json
                    },
                    {'user' => user}
    json = {:errors => ["POST entities should mention the database id in either entity[database_id] or as nested REST call"]}.to_json
    post_count = Entity.count
    assert_response 400
    assert_equal 0, post_count - pre_count, 'Entity count differs!'
    assert_equal json, @response.body, 'JSON Not Equal!'
    
    db = 8
    data = { :name => 'test_entity'}
    ######################################################################
    #                             CASE 03                                    
    # POST /:database_id/entities
    # A nested call with all correct
    #######################################################################
    pre_count = Entity.count
    
    post :create , {  :format => 'json',
                      :database_id => db,
                      :entity => data.to_json
                    },
                    {'user' => user}
    
    
    post_count = Entity.count
    assert_response 201
    assert_equal 1, post_count - pre_count, 'Entity count differs!'
    
    db = 198
    data = { :name => 'test_entity'}
    ######################################################################
    #                            CASE 04                                       
    # POST /:database_id/entities
    # A nested call with incorrect database
    #######################################################################
    pre_count = Entity.count
    
    post :create , {  :format => 'json',
                      :database_id => db,
                      :entity => data.to_json
                    },
                    {'user' => user}
    
    json = {:errors => ["Database[#{db}] does not exists"]}.to_json
    post_count = Entity.count
    assert_response 404
    assert_equal json, @response.body
    assert_equal 0, post_count - pre_count, 'Entity count differs!'
    
    
    
  end
  
  def test_delete
    user = User.find(@db1_admin_user_id)
    
    entity = 14
    lock_version = Entity.find(entity).lock_version.to_i
    ######################################################################
    #                                                                    
    # DELETE /entities/:id
    # with correct entity
    ######################################################################
    pre_count = Entity.count
    
    delete :destroy , {  :format => 'json',
                        :lock_version => lock_version,
                        :id => entity,
                    },
                    {'user' => user}
    
    
    post_count = Entity.count
    assert_response :success
    assert_equal 1, pre_count - post_count, 'Entity count differs!'
    #assert_equal  '', @response.body
    
    entity = 114
    lock_version = 79879
    ######################################################################
    #                                                                    
    # DELETE /entities/:id
    # with incorrect
    ######################################################################
    pre_count = Entity.count
    
    delete :destroy , {  :format => 'json',
                        :lock_version => lock_version,
                        :id => entity,
                    },
                    {'user' => user}
    
    
    post_count = Entity.count
    json = {:errors => ["Entity[#{entity}] does not exists."]}.to_json
    assert_response 404
    assert_equal 0, pre_count - post_count, 'Entity count differs!'
    assert_equal json, @response.body
    
    db = 8
    entity = 52
    lock_version = Entity.find(entity).lock_version.to_i
    ######################################################################
    #                                                                    
    # DELETE databases/:database_id/entities/:id
    # with all correct
    ######################################################################
    pre_count = Entity.count
    
    delete :destroy , {  :format => 'json',
                        :id => entity,
                        :lock_version => lock_version,
                        :database_id => db
                    },
                    {'user' => user}
    
    
    post_count = Entity.count
    assert_response :success
    assert_equal 1, pre_count - post_count, 'Entity count differs!'
    
    db = 8
    entity = 1952
    lock_version = 98797
    ######################################################################
    #                                                                    
    # DELETE databases/:database_id/entities/:id
    # with all correct db but incorrect entity
    ######################################################################
    pre_count = Entity.count
    
    delete :destroy , {  :format => 'json',
                        :id => entity,
                        :lock_version => lock_version,
                        :database_id => db
                    },
                    {'user' => user}
    
    
    json = {:errors => ["Entity[#{entity}] does not exists."]}.to_json
    post_count = Entity.count
    assert_response 404
    assert_equal 0, pre_count - post_count, 'Entity count differs!'
    assert_equal json, @response.body
    
    
    db = 884
    entity = 52
    lock_version = 797
    ######################################################################
    #                                                                    
    # DELETE databases/:database_id/entities/:id
    # with all incorrect db but correct enitty
    ######################################################################
    pre_count = Entity.count
    
    delete :destroy , {  :format => 'json',
                         :id => entity,
                         :lock_version => lock_version,
                         :database_id => db
                    },
                    {'user' => user}
              
    json = {:errors => ["Database[#{db}] does not exists."]}.to_json
    post_count = Entity.count
    assert_response 404
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body    
    
  end
  
  def test_delete_with_version_conflict
    # Get a resource
    # Get its lock version
    # modify resource
    # post it back
    user = User.find_by_id @db1_admin_user_id
    
    id = 100
    res_name = 'entity'
    lock_version = nil
    klass = Entity
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource = JSON.parse(@response.body)
    
    lock_version = resource['lock_version']
    
    # PUT it back
    put :update, {:format => 'json', res_name => resource.to_json, :id => id}, {'user' => user}
    
    message = 'Attempted to delete a stale object'
    pre_count = klass.count
    delete :destroy, {:format => 'json', :id => id, :lock_version => lock_version}, {'user' => user}
    post_count = klass.count
    assert_response 409
    assert_equal 0, post_count - pre_count

    assert_equal message, JSON.parse(@response.body)['message']

  end  
  
  def test_delete_without_version
    user = User.find(@db1_admin_user_id)
    
    entity = 14
    
    ######################################################################
    #                                                                    
    # DELETE /entities/:id
    # with correct entity
    ######################################################################
    pre_count = Entity.count
    json = {:errors => ["Provide lock_version for update/delete operations"]}.to_json
    delete :destroy , {  :format => 'json',
                        #:lock_version => lock_version,
                        :id => entity
                    },
                    {'user' => user}
    
    
    post_count = Entity.count
    assert_response 400
    assert_equal json, @response.body
    assert_equal 0, pre_count - post_count, 'Entity count differs!'
  end
  

end
