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
require 'rest/databases_controller'
require 'json'
# 
# assert_response status_code
# assert_redirect
# assert_redirect_to
# Re-raise errors caught by the controller.
class Rest::DatabasesController; def rescue_action(e) raise e end; end

#FIXME: Add the tests for getting wrong id databases.
class DatabasesControllerTest < Test::Unit::TestCase
  
  fixtures   :account_types, 
             :accounts,
             :databases,
             :user_types, 
             :users, 
             :entities, 
             :data_types, 
             :detail_status, 
             :details, 
             :instances, 
             :detail_values

         
         
  def setup
    @controller   = Rest::DatabasesController.new
    @request      = ActionController::TestRequest.new
    @response      = ActionController::TestResponse.new
    
    @db1_number_of_entities = 8 
    @db1_admin_user_id = 2
    @db1_normal_user_id = 1000001
    @db1_entity_id = 11
    @db1_instance_id = 77
    @db2_user_id= 1000003
    @db2_admin_user_id = 1000004
    
  end
  
  def test_without_login
    #FIXME: will be done after REST Auth
    assert true
#    id = 6
#    get :show, {:format => 'json', :id => id}, {'user' => nil}
#    assert_response 401
#    json = %Q~{"errors": ["Please login to consume the REST API"]}~
#    assert_equal json, @response.body  
  end
  
  def test_accessing_irrelevant_item
    # CASE 01:  GET /database/ where database irrelevant
    # CASE 02: GET /accounts/databaes where account is irrelevant
    
    res_id = 5
    res_name = 'Database'
    user = User.find @db1_admin_user_id
    json = {:errors =>["#{res_name}[#{res_id}] does not belong to User[#{user.id}] (\"#{user.login}\")"]}.to_json
    get :show, {:format => 'json', :id => res_id}, {'user' => user}
    assert_equal json, @response.body
  end
  
  def test_accessing_without_adminstrative_rights
    
    #FIXME: Depeneds upon REST Auth
    assert true
#    user  = User.find @db1_normal_user_id
#    
#    get :index, {:format => 'json'}, {'user' => user}
#    
#    assert_response 200
#    
#    
#    resource_name = :database
#    resource = %Q~{"name": "asf"}~
#    msg = {:errors => ['This REST call needs administrative rights']}
#    
#    post :create, {:format => 'json', resource_name => resource}, {'user' => user}
#    assert_response 403
#    assert_equal msg.to_json, @response.body
#    
#    put :update, {:format => 'json', resource_name => resource}, {'user' => user}
#    assert_response 403
#    assert_equal msg.to_json, @response.body
#    
#    delete :destroy, {:format => 'json', :id => 45}, {'user' => user}
#    assert_response 403
#    
#    
  end
  
  # *Description*
  #   This tests the following URLs:
  #   GET /databases
  #
  def test_get_all
    # CASE 01: GET /databases
    # CASE 02: GET /accounts/:account_id/databases
    # CASE 03: GET /accounts/:account_id/databases with wrong account id
    
    ####################################################################
    #                            CASE 01
    #     GET /databases
    ####################################################################
    user = User.find_by_id(@db1_admin_user_id)
    
    assert_not_nil user, "User was not found in the test database!"
    # Get the JSON of all the databases of the account of this user
    json = Database.find(:all, :conditions => ["account_id = ?", user.account_id])
    
    # GET /databases
    get :index, {'format' => 'json'}, {'user' => user}  
    
    # We suceed?
    assert_response 200
    result = JSON.parse(@response.body)
    # The JSONs are same?
    assert_equal json.length, result['resources'].length, "The expected JSON and reutrn JSON not equal"
    
    
    JSON.parse(@response.body)
    
    account_id = user.account_id
    ####################################################################
    #                            CASE 02
    #     GET /accounts/:account_id/databases
    ####################################################################
    # Get the JSON of all the databases of the account of this user
    json = Database.find(:all, :conditions => ["account_id = ?", user.account_id])
    get :index, {:format => 'json', :account_id => account_id}, {'user' => user}  
    assert_response 200
    result = JSON.parse(@response.body)
    assert_equal json.length, result['resources'].length, "The expected JSON and reutrn JSON not equal"
    
    
    account_id = 464785
    ####################################################################
    #                            CASE 03
    #     GET /accounts/:account_id/databases with wrong account id
    ####################################################################
    # Get the JSON of all the databases of the account of this user
    json = {:errors => ["Account[#{account_id}] does not exists"]}.to_json
    get :index, {:format => 'json', :account_id => account_id}, {'user' => user}  
    assert_response 404
    assert_equal json, @response.body, "The expected JSON and reutrn JSON not equal"
    #JSON.parse(@response.body)
    
    
  end
  
  def test_get_all_with_pagination
    # CASE 01: Mention of start_index and max_results
    # CASE 02: Mention of Order by with direction
    # CASE 03: Mention of Order by without direction
    # CASE 04: Mention a condition also
    user = User.find_by_id(@db1_admin_user_id)
    
    parent_resource = :account_id
    parent_id = 1
    start_index = 10
    max_results = 10
    order_by = 'name'
    direction = 'DESC'
    table_name = 'databases'
    conditions = 'account_id=1'
    total_records = Database.count_by_sql "SELECT COUNT(*) FROM  #{table_name} WHERE #{conditions}"
    conditions = 'id=6'
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

    assert_equal 4, result['resources'].length
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

    assert_equal 4, result['resources'].length
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

    assert_equal result['resources_returned'], result['resources'].length
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
  
  # *Dscription*
  #  GET /databases/:id
  def test_get_single
    # CASE 01: GET /databases/:id with all ok
    # CASE 02: GET /databases/:id with wrong id
    
    user = User.find_by_id @db1_admin_user_id

    database = 6
    ########################################################################
    #                            CASE 01
    #   GET /databases/:id with all ok
    ########################################################################
    model = Database.find(database)
    
    get :show, {:format => 'json', :id => database}, {'user' => user}
    assert_response :success
    assert_similar model, @response.body
    
    # Get a wrong ID database
    
    database = 97979 #6
    ########################################################################
    #                            CASE 02
    #   GET /databases/:id with wrong id
    ########################################################################
    json = {:errors => ["Database[#{database}] does not exists"]}.to_json    
    get :show, {:format => 'json', :id => database}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body, "Expected json and returned json are different"
    JSON.parse(@response.body)
    
  end
  
  def test_get_single_with_account
    # CASE 01: GET /accounts/databases/:id with all ok
    # CASE 02: GET /accounts/databases/:id with wrong database
    # CASE 03: GET /accounts/databases/:id with wrong account
    # CASE 04: GET /accounts/databases/:id with both irrelevant
    
    user = User.find_by_id(@db1_admin_user_id)
    
    database = 6
    account = 1
    #########################################################################
    #                             CASE 01
    #   GET /accounts/databases/:id with all ok
    #########################################################################
    model = Database.find(database)
    get :show, {:format => 'json', :account_id => account, :id => database},
      {'user' => user}
    
    assert_response :success
    assert_similar model, @response.body
    
    
    database = 97979 #6
    account = 1
    #########################################################################
    #                             CASE 02
    #   GET /accounts/databases/:id with all ok
    #########################################################################
    json = {:errors => ["Database[#{database}] does not exists"]}.to_json
    get :show, {:format => 'json', :account_id => account, :id => database},
      {'user' => user}
    
    assert_response 404
    assert_equal json, @response.body
    JSON.parse(@response.body)
    
    database = 6
    account = 9797 #1
    #########################################################################
    #                             CASE 03
    #   GET /accounts/databases/:id with all ok
    #########################################################################
    json = {:errors => ["Account[#{account}] does not exists"]}.to_json
    get :show, {:format => 'json', :account_id => account, :id => database},
      {'user' => user}
    
    assert_response 404
    assert_equal json, @response.body
    JSON.parse(@response.body)
    
    database = 5 #6
    account = 1
    #########################################################################
    #                             CASE 03
    #   GET /accounts/databases/:id with all ok
    #########################################################################
    json = {:errors => ["Database[#{database}] does not belong to Account[#{account}]"]}.to_json
    get :show, {:format => 'json', :account_id => account, :id => database},
      {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    JSON.parse(@response.body)
    
    
  end
  
  # *Description*
  # PUT /databases/:id
  def test_put
    # CASE 01: PUT /databases/:id with all ok
    # CASE 02: PUT /databases/:id with wrong id
    # CASE 03: PUT /databases/:id with resource missing
    
    
    user = User.find_by_id(@db1_admin_user_id)
    
    database = 6
    
    res = {:name => 'TEST DB'}
    res[:lock_version] = Database.find(database).lock_version.to_i
    #########################################################################
    #                             CASE 01
    #   PUT /databases/:id with all ok
    #########################################################################
    put :update, {:format => 'json', :database => res.to_json, :id => database},
      {'user' => user}
    model = Database.find(database)
    assert_response :success
    assert_similar model, @response.body
    
    
    database = 9797 #6
    res = {:name => 'TEST DB'}
    res[:lock_version] = 98798
    #########################################################################
    #                             CASE 02
    #   PUT /databases/:id with wrong id
    #########################################################################
    put :update, {:format => 'json', :database => res.to_json, :id => database},
      {'user' => user}
    json = {:errors => ["Database[#{database}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body
    JSON.parse(@response.body)
    
    database = 6
    res = {:name => 'TEST DB'}
    res[:lock_version] = Database.find(database).lock_version.to_i
    #########################################################################
    #                             CASE 03
    #   PUT /databases/:id with resource missing
    #########################################################################
    put :update, {:format => 'json',  :id => database},
      {'user' => user}
    json = {:errors => ['Provide the database resource to be created/updated']}.to_json
    assert_response 400
    assert_equal json, @response.body
    JSON.parse(@response.body)
    
  end
  
  def test_put_without_lock_version
    
    user = User.find_by_id(@db1_admin_user_id)
    
    database = 6
    res = {:name => 'TEST DB'}
    #########################################################################
    #                             CASE 03
    #   PUT /databases/:id with resource missing
    #########################################################################
    put :update, {:format => 'json',  :id => database, :database => res.to_json},
      {'user' => user}
    json = {:errors => ["Provide lock_version for update/delete operations"]}.to_json
    assert_response 400
    assert_equal json, @response.body
    JSON.parse(@response.body)
  end
  
  def test_put_with_account
    # CASE 01: PUT /accounts/databases/:id with all ok
    # CASE 02: PUT /accounts/databases/:id with wrong database
    # CASE 03: PUT /accounts/databases/:id with wrong account
    # CASE 04: PUT /accounts/databases/:id with both irrelevant
    # CASE 05: PUT /accounts/databases/:id with resource missing
    
    user = User.find_by_id(@db1_admin_user_id)
    
    database = 6
    account = 1
    res = {:name => 'TEST DB'}
    res[:lock_version] = Database.find(database).lock_version.to_i
    #########################################################################
    #                             CASE 01
    #   PUT /accounts/databases/:id with all ok
    #########################################################################
    get :update, {:format => 'json', :database => res.to_json, :account_id => account, :id => database},
      {'user' => user}
    model = Database.find(database)
    assert_response :success
    assert_similar model, @response.body
    
    
    database = 97979 #6
    account = 1
    res[:lock_version] = 9797
    #########################################################################
    #                             CASE 02
    #   PUT /accounts/databases/:id with all ok
    #########################################################################
    json = {:errors => ["Database[#{database}] does not exists"]}.to_json
    get :update, {:format => 'json', :database => res.to_json, :account_id => account, :id => database},
      {'user' => user}
    
    assert_response 404
    assert_equal json, @response.body
    JSON.parse(@response.body)
    
    database = 6
    account = 9797 #1
    res[:lock_version] = 987987
    #########################################################################
    #                             CASE 03
    #   PUT /accounts/databases/:id with all ok
    #########################################################################
    json = {:errors => ["Account[#{account}] does not exists"]}.to_json
    get :update, {:format => 'json', :database => res.to_json, :account_id => account, :id => database},
      {'user' => user}    
    assert_response 404
    assert_equal json, @response.body
    JSON.parse(@response.body)
    
    database = 5 #6
    account = 1
    res[:lock_version] = 9879
    #########################################################################
    #                             CASE 04
    #   GET /accounts/databases/:id with all ok
    #########################################################################
    json = {:errors => ["Database[#{database}] does not belong to Account[#{account}]"]}.to_json
    get :update, {:format => 'json', :database => res.to_json, :account_id => account, :id => database},
      {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    JSON.parse(@response.body)
    
    database = 6
    account = 1
    res = {:name => 'TEST DB'}
    res[:lock_version] = Database.find(database).lock_version.to_i
    #########################################################################
    #                             CASE 01
    #   PUT /accounts/databases/:id with all ok
    #########################################################################
    json = {:errors => ["Provide the database resource to be created/updated"]}.to_json
    get :update, {:format => 'json', :account_id => account, :id => database},
      {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    JSON.parse(@response.body)
    
  end
  
  def test_get_and_put
    user = User.find_by_id @db1_admin_user_id
    
    id = 1
    res_name = 'database'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource = JSON.parse(@response.body)
    
    resource['name'] = 'GET AND PUT TEST'
    
    put :update, {:format => 'json', :id => 1, res_name => resource.to_json}, {'user' => user}
    #assert_equal '', @response.body
    assert_response 200
    new_val = JSON.parse(@response.body)
    assert_equal resource['name'], new_val['name']    
    
  end
  
  def test_get_and_put_conflict
    user = User.find_by_id @db1_admin_user_id
    
    id = 1
    res_id = 78
    res_name = 'database'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource = JSON.parse(@response.body)
    
    resource['name'] = 'GET AND PUT TEST'
    resource['url'] = 'http://localhost:300/databases/' + res_id.to_s + '.json'
    
    json = {:errors => ["Requested ID is #{id} and ID in resource is #{res_id}. Are you dispatching your resource at the right location?"]}.to_json
    put :update, {:format => 'json', :id => id, res_name => resource.to_json}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
  end
  
  def test_get_and_put_version_conflict
    user = User.find_by_id @db1_admin_user_id
    
    id = 1
    res_name = 'database'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource1 = JSON.parse(@response.body)
    
    resource1['name'] = 'GET AND PUT TEST'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource2 = JSON.parse(@response.body)
    
    resource2['name'] = 'GET AND PUT TEST8'
    
    put :update, {:format => 'json', :id => 1, res_name => resource1.to_json}, {'user' => user}
    assert_response 200
    new_val = JSON.parse(@response.body)
    assert_equal resource1['name'], new_val['name']    
    
    message = "Attempted to update a stale object"
    put :update, {:format => 'json', :id => 1, res_name => resource2.to_json}, {'user' => user}
    assert_response 409

    assert_equal message, JSON.parse(@response.body)['message']

    
    
    
    
  end
  
  # *Description*
  #   POST /databases
  #
  def test_post
    # POST /accounts/databases/ with all ok
    # POST /databases/ with resource missing
    user = User.find_by_id @db1_admin_user_id
    
    res = {:name => 'nametestdbcreation'}
    ###################################################################
    #                             CASE 01
    #   POST /databases/ with all ok
    ###################################################################
    pre_count = Database.count
    post :create, {:format => 'json', :database => res.to_json}, {'user' => user}
    post_count = Database.count
    #assert_equal '', @response.body
    assert_response 201
    assert_equal 1, post_count - pre_count
    #assert_equal '', @response.body
    
    res = {:name => 'nametestdbcreation'}
    ###################################################################
    #                             CASE 02
    #   POST /databases/ with resource missing
    ###################################################################
    pre_count = Database.count
    json = {:errors => ["Provide the database resource to be created/updated"]}.to_json
    post :create, {:format => 'json'}, {'user' => user}
    post_count = Database.count
    assert_response 400
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    
  end
  
  def test_post_with_account
    # CASE 01: POST /account/databases/ with all ok
    # CASE 02: POST /account/databases/ with resource missing
    # CASE 03: POST /account/databases/ with wrong account id
    user = User.find_by_id @db1_admin_user_id
    
    res = {:name => 'nametestdbcreation'}
    account = 1
    ###################################################################
    #                             CASE 01
    #   POST /accounts/databases/ with all ok
    ###################################################################
    pre_count = Database.count
    post :create, {:format => 'json', :account_id => account, :database => res.to_json}, {'user' => user}
    post_count = Database.count
    assert_response 201
    assert_equal 1, post_count - pre_count
    #assert_equal '', @response.body
    
    res = {:name => 'nametestdbcreation'}
    account = 1
    ###################################################################
    #                             CASE 02
    #   POST /accounts/databases/ with resource missing
    ###################################################################
    pre_count = Database.count
    json = {:errors => ["Provide the database resource to be created/updated"]}.to_json
    post :create, {:format => 'json', :account_id => account}, {'user' => user}
    post_count = Database.count
    assert_response 400
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    
    res = {:name => 'nametestdbcreation'}
    account = 79797 #1
    ###################################################################
    #                             CASE 03
    #   POST /accounts/databases/ with wrong account id
    ###################################################################
    pre_count = Database.count
    json = {:errors => ["Account[#{account}] does not exists"]}.to_json
    post :create, {:format => 'json', :database => res.to_json, :account_id => account}, {'user' => user}
    post_count = Database.count
    assert_response 404
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
  end
  
  # Description
  #   DELETE /database/:id
  #
  def test_delete
    # CASE 01: DELETE /databases/:id with all ok
    # CASE 02: DELETE /databases/:id with wrong id
    user = User.find_by_id @db1_admin_user_id
    
    database = 6
    lock_version = Database.find(database).lock_version.to_i
    ########################################################################
    #                            CASE 01
    #   GET /databases/:id with all ok
    ########################################################################
    json = Database.find(database).to_json(:format => 'json')
    pre_count = Database.count
    delete :destroy, {:format => 'json', :id => database, :lock_version => lock_version}, {'user' => user}
    post_count = Database.count
    
    assert_response :success
    assert_equal 1, pre_count - post_count
   #assert_equal '', @response.body
    # Get a wrong ID database
    
    database = 97979 #6
    ########################################################################
    #                            CASE 02
    #   GET /databases/:id with wrong id
    ########################################################################
    json = {:errors => ["Database[#{database}] does not exists"]}.to_json    
    delete :destroy, {:format => 'json',:lock_version => 1, :id => database}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body, "Expected json and returned json are different"
    JSON.parse(@response.body)
    

  end
  
  def test_delete_with_version_conflict
    # Get a resource
    # Get its lock version
    # modify resource
    # post it back
    user = User.find_by_id @db1_admin_user_id
    
    id = 6
    res_name = 'database'
    lock_version = nil
    klass = Database
    
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
  
  def test_delete_with_lock_missing
    
    user = User.find_by_id @db1_admin_user_id
    
    database = 6
    ########################################################################
    #                            CASE 03
    #   GET /databases/:id with lock_version missing
    ########################################################################
    json = {:errors => ["Provide lock_version for update/delete operations"]}.to_json    
    delete :destroy, {:format => 'json', :id => database}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body, "Expected json and returned json are different"
    JSON.parse(@response.body)
    
  end
  
  def test_delete_with_lock_wrong
    
    user = User.find_by_id @db1_admin_user_id
    
    database = 6
    lock_version = 7987987
    ########################################################################
    #                            CASE 01
    #   GET /databases/:id with all ok
    ########################################################################
    message = "Attempted to delete a stale object"
    
    delete :destroy, {:format => 'json', :id => database, :lock_version => lock_version}, {'user' => user}
    assert_response 409

    assert_equal message, JSON.parse(@response.body)['message']

    
  end
  
  def test_delete_with_account
    # CASE 01: DELETE /accounts/databases/:id with all ok
    # CASE 02: DELETE /accounts/databases/:id with wrong database
    # CASE 03: DELETE /accounts/databases/:id with wrong account
    # CASE 04: DELETE /accounts/databases/:id with both irrelevant
    
    user = User.find_by_id(@db1_admin_user_id)
    
    database = 97979 #6
    account = 1
    lock_version = 7987987
    #########################################################################
    #                             CASE 02
    #   DELETE /accounts/databases/:id with wrong database
    #########################################################################
    json = {:errors => ["Database[#{database}] does not exists"]}.to_json
    pre_count = Database.count
    delete :destroy, {:format => 'json', :lock_version => lock_version, :account_id => account, :id => database},
      {'user' => user}
    post_count = Database.count
    assert_response 404
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    JSON.parse(@response.body)
    
    database = 6
    account = 9797 #1
    lock_version = Database.find(database).lock_version
    #########################################################################
    #                             CASE 03
    #   DELETE /accounts/databases/:id with wrong aaccount
    #########################################################################
    json = {:errors => ["Account[#{account}] does not exists"]}.to_json
    pre_count = Database.count
    delete :destroy, {:format => 'json', :lock_version => lock_version, :account_id => account, :id => database},
      {'user' => user}
    post_count = Database.count
    assert_response 404
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    JSON.parse(@response.body)
    
    database = 5 #6
    account = 1
    lock_version = Database.find(database).lock_version
    #########################################################################
    #                             CASE 03
    #   DELETE /accounts/databases/:id with both irrelevant
    #########################################################################
    json = {:errors => ["Database[#{database}] does not belong to Account[#{account}]"]}.to_json
    pre_count = Database.count
    delete :destory, {:format => 'json', :lock_version => lock_version, :account_id => account, :id => database},
      {'user' => user}
    post_count = Database.count
    assert_response 400
    assert_equal 0, post_count -pre_count
    assert_equal json, @response.body
    JSON.parse(@response.body)
    
    database = 6
    account = 1
    lock_version = Database.find(database).lock_version
    #########################################################################
    #                             CASE 01
    #   DELETE /accounts/databases/:id with all ok
    #########################################################################
    json = Database.find(database).to_json(:format => 'json')
    pre_count = Database.count
    delete :destroy, {:format => 'json', :lock_version => lock_version, :account_id => account, :id => database},
      {'user' => user}
    post_count = Database.count
    
    assert_response :success
    assert_equal 1, pre_count - post_count
    #assert_equal '', @response.body
      
    
    
  end
  
end
