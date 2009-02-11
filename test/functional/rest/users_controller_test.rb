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
require 'rest/users_controller'


# assert_response status_code
# assert_redirect
# assert_redirect_to
# Re-raise errors caught by the controller.
class Rest::UsersController; def rescue_action(e) raise e end; end

#FIXME: Only test_get_single covers all the posible combination of ids

class UsersControllerTest < Test::Unit::TestCase
  
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
    @controller   = Rest::UsersController.new
    @request      = ActionController::TestRequest.new
    @response      = ActionController::TestResponse.new
    
    @db1_admin_user_id = 2
    @db1_normal_user_id = 1000001
  end
  
  def test_without_login
    assert true
#    id = 1
#    get :show, {:format => 'json', :id => id}, {'user' => nil}
#    assert_response 401
#    json = %Q~{"errors": ["Please login to consume the REST API"]}~
#    assert_equal json, @response.body  
  end
  
  def test_accessing_irrelevant_item
    res_id = 6
    res_name = 'User'
    user = User.find @db1_admin_user_id
    json = {:errors =>["#{res_name}[#{res_id}] does not belong to User[#{user.id}] (\"#{user.login}\")"]}.to_json
    get :show, {:format => 'json', :id => res_id}, {'user' => user}
    assert_equal json, @response.body
    
    res_id = 6
    account = 100
    res_name = 'Account'
    user = User.find @db1_admin_user_id
    json = {:errors =>["#{res_name}[#{account}] does not belong to User[#{user.id}] (\"#{user.login}\")"]}.to_json
    get :show, {:format => 'json', :account_id => account, :id => res_id}, {'user' => user}
    assert_equal json, @response.body
  end
  
  def test_accessing_without_adminstrative_rights
    # will be rewritten after REST Auth
    assert true
#    user  = User.find @db1_normal_user_id
#    parent = :account_id
#    parent_id = 1
#    id = 100
#    
#    get :index, {:format => 'json', parent => parent_id}, {'user' => user}
#    assert_response 200
#    
#    get :show, {:format => 'json', :id => id}, {'user' => user}
#    assert_response 200
#    
#    resource_name = :user
#    resource = %Q~{"name": "asf"}~
#    msg = {:errors => ['This REST call needs administrative rights']}
#    
#    post :create, {:format => 'json', resource_name => resource}, {'user' => user}
#    assert_equal '', @response.body
#    assert_response 403
#    assert_equal msg.to_json, @response.body
#    
#    put :update, {:format => 'json', resource_name => resource}, {'user' => user}
#    assert_response 403
#    assert_equal msg.to_json, @response.body
#    
#    delete :destroy, {:format => 'json', :id => 45}, {'user' => user}
#    assert_response 403
#    #assert_equal '', @response.body
#    
  end
  
  def test_get_all
    # CASE 01: GET /users?account=id all ok
    # CASE 02: GET /users?account=id account wrong
    # CASE 03: GET /users without account
    
    user = User.find @db1_admin_user_id
    
    account = 1
    ##################################################################
    #                           CASE 01
    #  GET /users?account=id with all ok
    ##################################################################
    json = User.find(:all, :conditions => ["account_id=?", account])
    get :index, {:format => 'json', :account_id => account}, {'user' => user}
    assert_response :success
    result = JSON.parse(@response.body)
    assert_equal json.length, result['resources'].length
    
    
    account = 9877 #1
    ##################################################################
    #                           CASE 02
    #  GET /users?account=id with worng account
    ##################################################################
    json = {:errors =>  [ "Account[#{account}] does not exists"]}.to_json
    get :index, {:format => 'json', :account_id => account}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    
    account = 1
    ##################################################################
    #                           CASE 03
    #  GET /users without mention of account
    ##################################################################
    json = {:errors => [ "GET /users not allowed, use GET accounts/:account_id/users instead"]}.to_json
    get :index, {:format => 'json'}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    
  end
  
  def test_get_all_with_pagination
    # CASE 01: Mention of start_index and max_results
    # CASE 02: Mention of Order by with direction
    # CASE 03: Mention of Order by without direction
    # CASE 04: Mention a condition also
    
    user = User.find_by_id(@db1_admin_user_id)
    
    parent_resource = :account_id
    parent_id = 1
    start_index = 0
    max_results = 3
    order_by = 'name'
    direction = 'DESC'
    table_name = 'data_types'
    conditions = 'database_id=6'
    #total_records = Detail.count_by_sql "SELECT COUNT(*) FROM  #{table_name} WHERE #{conditions}"
    conditions = 'id=50'
    
    total_records = User.count :conditions => "account_id=#{parent_id}"
    max_results = 2
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
    result = JSON.parse result
    assert_equal max_results, result['resources'].length
    assert_equal total_records, result['total_resources']
    
    
    
    order_by = 'login'
    direction = 'desc'
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
    result = JSON.parse result
    assert_equal max_results, result['resources'].length
    assert_equal 'desc', result['direction']
    assert_equal 2, result['resources'][0]['url'].chomp('.json')[/\d+$/].to_i
    
    #########################################################
    #                        CASE 03
    #        Mention of order by without direction
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
    result = JSON.parse result
    assert_equal max_results, result['resources'].length
    assert_equal 'asc', result['direction']
    assert_equal 1000001, result['resources'][0]['url'].chomp('.json')[/\d+$/].to_i
    
    conditions = "firstname='Mohsin'"
    #########################################################
    #                        CASE 04
    #        Mention of order by specifying condition
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
    result = JSON.parse result
    assert_equal 1, result['resources'].length
    assert_equal 'asc', result['direction']
    assert_equal 100, result['resources'][0]['url'].chomp('.json')[/\d+$/].to_i
  end
  
  def test_get_single
    # CASE 01: GET /users/:id with all ok
    # CASE 02: GET /users/:id with wrong id
    # CASE 03: GET /accounts/users with all ok
    # CASE 04: GET /accounts/users/ both not belonging to each other
    # CASE 05: GET /accounts/users/ wrong account
    
    user = User.find @db1_admin_user_id
    
    user_id = 1000001
    ################################################################
    #                      CASE 01
    #  GET /users/:id with all ok
    ################################################################
    model = User.find(user_id)
    get :show, {:format => 'json', :id => user_id}, {'user' => user}
    assert_response :success
    assert_similar model, @response.body, [:created_at]
    
    
    user_id = 87878 #1000001
    ################################################################
    #                      CASE 02
    #  GET /users/:id with inexisting user
    ################################################################
    json = {:errors => [ "User[#{user_id}] does not exists"]}.to_json
    get :show, {:format => 'json', :id => user_id}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    
    user_id = 2
    account_id = 1
    ################################################################
    #                      CASE 03
    #  GET accounts/:account_id/users/:id with all ok
    ################################################################
    model = User.find(user_id)
    get :show, {:format => 'json', :account_id => account_id, :id => user_id}, {'user' => user}
    assert_response 200
    assert_similar model, @response.body
    
    user_id = 6
    account_id = 1
    ################################################################
    #                      CASE 04
    #  GET accounts/:account_id/users/:id with not belonging to each other
    ################################################################
    json = {:errors => ["User[#{user_id}] does not belong to Account[#{account_id}]"]}.to_json
    get :show, {:format => 'json', :account_id => account_id, :id => user_id}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    
    user_id = 6
    account_id = 1234234
    ################################################################
    #                      CASE 04
    #  GET accounts/:account_id/users/:id with not belonging to each other
    ################################################################
    json = {:errors => ["Account[#{account_id}] does not exists"]}.to_json
    get :show, {:format => 'json', :account_id => account_id, :id => user_id}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body
  end
  
  def test_post
    # CASE 01: POST /users with user resource
    # CASE 02: POST /users without user resource
    
    user = User.find(@db1_admin_user_id)
    
    user_resource = {
:login => 'mohsinhijazee@yahoo.com', 
:login_confirmation => 'mohsinhijazee@yahoo.com',
:user_type_id => 1,
:account_id => 1,
:firstname => 'Mohsin', 
:lastname => 'Hijazee', 
:email => 'mohsinhijazee@yahoo.com',
:password => 'asdfasdfasdf', 
:password_confirmation => 'asdfasdfasdf'
}
 
    ################################################################
    #                           CASE 01
    #   POST /users with user resource
    ################################################################
    pre_count = User.count
    post :create, {:format => 'json', :user => user_resource.to_json}, {'user' => user}
    post_count = User.count
    #assert_equal '', @response.body
    assert_response 201
    assert_equal 1, post_count - pre_count
    #assert_equal '', @response.body
    
    ################################################################
    #                           CASE 02
    #   POST /users without user resource
    ################################################################
    json = {:errors => [ "Provide user resource to be created/updated"]}.to_json
    pre_count = User.count
    post :create, {:format => 'json'}, {'user' => user}
    post_count = User.count
    assert_response 400
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    
    
  end
  
  def test_put
    # CASE 01: PUT /users/:id with user resource and correct id
    # CASE 02: PUT /users/:id with incorrect id
    # CASE 03: PUT /users/:id without user resource
    
    user = User.find(@db1_admin_user_id)
    
    user_resource = {"firstname" => "Mohsin", "lastname" => "Hijazee", "email"=> "m_hijazee@yahoo.com"}
    user_id = 1000002
    #user_resource[:lock_version] = User.find(user_id).lock_version.to_i
    #############################################################
    #                         CASE 01
    #  PUT /users/:id with correct id and resource
    #############################################################
    put :update, {:format => 'json', :id => user_id, :user => user_resource.to_json}, {'user' => user}
    assert_response :success
    u = User.find user_id
    assert_equal u.firstname, 'Mohsin'
    assert_equal u.lastname, 'Hijazee'
    assert_equal u.email, 'm_hijazee@yahoo.com'
    JSON.parse(@response.body)
    #assert_equal '', @response.body
    
    user_resource = {"firstname" => "Mohsin", "lastname" => "Hijazee", "email" => "m_hijazee@yahoo.com"}
    #user_resource[:lock_version] = 7979
    user_id = 7547 #1000002
    #############################################################
    #                         CASE 02
    #  PUT /users/:id with incorrect id and resource
    #############################################################
    json = {:errors => [ "User[#{user_id}] does not exists"]}.to_json
    put :update, {:format => 'json', :id => user_id, :user => user_resource.to_json}, {'user' => user}
    #assert_equal '', @response.body
    assert_response 404
    assert_equal json, @response.body
    
    user_resource = {"firstname" => "Mohsin", "lastname" => "Hijazee", "email" => "m_hijazee@yahoo.com"}
    user_id = 7547 #1000002
    #user_resource[:lock_version] = 9797
    #############################################################
    #                         CASE 03
    #  PUT /users/:id without user resoruce
    #############################################################
    json = {:errors => ["Provide user resource to be created/updated"]}.to_json
    put :update, {:format => 'json', :id => user_id}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    
  end
  
#  def test_put_without_lock_version
#    
#    user = User.find(@db1_admin_user_id)
#    
#    user_resource = {"firstname" => "Mohsin", "lastname" => "Hijazee", "email"=> "m_hijazee@yahoo.com"}
#    user_id = 1000002
#    #user_resource[:lock_version] = User.find(user_id).lock_version.to_i
#    #############################################################
#    #                         CASE 01
#    #  PUT /users/:id with correct id and resource
#    #############################################################
#    json = {:errors => ['Provide lock_version for update/delete operations']}.to_json
#    put :update, {:format => 'json', :id => user_id, :user => user_resource.to_json}, {'user' => user}
#    assert_response 400
#    assert_equal json, @response.body
#    JSON.parse(@response.body)
#    #assert_equal '', @response.body
#  end
  
      
  def test_get_and_put
    user = User.find_by_id @db1_admin_user_id
    
    id = 100
    res_name = 'user'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    #assert_equal '', @response.body
    assert_response 200
    resource = JSON.parse(@response.body)
    
    
    resource['firstname'] = 'GET AND PUT TEST'
    
    put :update, {:format => 'json', :id => id, res_name => resource.to_json}, {'user' => user}
    #assert_equal '', @response.body
    
    assert_response 200
    new_val = JSON.parse(@response.body)
    assert_equal resource['firstname'], new_val['firstname']    
    
  end
  
  def test_get_and_put_conflict
    user = User.find_by_id @db1_admin_user_id
    
    id = 100
    res_id = 78
    res_name = 'user'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource = JSON.parse(@response.body)
    
    resource['firstname'] = 'GET AND PUT TEST'
    resource['url'] = 'http://localhost:300/users/' + res_id.to_s + '.json'
    
    json = {:errors => ["Requested ID is #{id} and ID in resource is #{res_id}. Are you dispatching your resource at the right location?"]}.to_json
    put :update, {:format => 'json', :id => id, res_name => resource.to_json}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
  end
  
#  def test_get_and_put_version_conflict
#    user = User.find_by_id @db1_admin_user_id
#    
#    id = 100
#    res_name = 'user'
#    
#    get :show, {:format => 'json', :id => id}, {'user' => user}
#    resource1 = JSON.parse(@response.body)
#    
#    resource1['firstname'] = 'GET AND PUT TEST'
#    
#    get :show, {:format => 'json', :id => id}, {'user' => user}
#    resource2 = JSON.parse(@response.body)
#    
#    resource2['firstname'] = 'GET AasddfasfND PUT TEST'
#    
#    put :update, {:format => 'json', :id => id, res_name => resource1.to_json}, {'user' => user}
#    #assert_equal '', @response.body
#    assert_response 200
#    new_val = JSON.parse(@response.body)
#    assert_equal resource1['firstname'], new_val['firstname']    
#    
#    json = {:errors => ["Attempted to update a stale object"]}.to_json
#    put :update, {:format => 'json', :id => id, res_name => resource2.to_json}, {'user' => user}
#    assert_equal json, @response.body
#    assert_response 409
#    assert_equal json, @response.body
#    
#    
#    
#    
#  end
    
  
  
  
  def test_delete
    # CASE 01: DELETE /users/:id with correct id
    # CASE 02: DELETE /users/:id with incorrect id
    
    user = User.find(@db1_admin_user_id)
    
    user_id = 1000002
    lock_version = nil #User.find(user_id).lock_version.to_i
    #####################################################################
    #                             CASE 01
    #  DELETE /users/:id with correct id
    #####################################################################
    pre_count = User.count
    #delete :destroy, {:format => 'json', :lock_version => lock_version,  :id => user_id }, {'user' => user }
    delete :destroy, {:format => 'json', :lock_version => lock_version,  :id => user_id }, {'user' => user }
    post_count = User.count
    assert_response :success
    assert_equal(-1, post_count - pre_count)
    
    user_id = 1222 #1000002
    lock_version = 97987
    #####################################################################
    #                             CASE 02
    #  DELETE /users/:id with incorrect id
    #####################################################################
    json = {:errors => [ "User[#{user_id}] does not exists"]}.to_json
    pre_count = User.count
    delete :destroy, {:format => 'json', :lock_version => lock_version, :id => user_id }, {'user' => user }
    post_count = User.count
    assert_response 404
    assert_equal json, @response.body
    assert_equal(0, post_count - pre_count)
    
  end
  
#  def test_delete_with_version_conflict
#    # Get a resource
#    # Get its lock version
#    # modify resource
#    # post it back
#    user = User.find_by_id @db1_admin_user_id
#    
#    id = 1000001
#    res_name = 'user'
#    lock_version = nil
#    klass = User
#    
#    get :show, {:format => 'json', :id => id}, {'user' => user}
#    resource = JSON.parse(@response.body)
#    
#    lock_version = resource['lock_version']
#    
#    # PUT it back
#    put :update, {:format => 'json', res_name => resource.to_json, :id => id}, {'user' => user}
#    
#    json = {:errors => ['Attempted to delete a stale object']}.to_json
#    pre_count = klass.count
#    delete :destroy, {:format => 'json', :id => id, :lock_version => lock_version}, {'user' => user}
#    post_count = klass.count
#    #assert_response 409
#    assert_equal 0, post_count - pre_count
#    assert_equal json, @response.body
#  end  
  
#  def test_delete_without_lock_version
#    
#    user = User.find(@db1_admin_user_id)
#    
#    user_id = 1000002
#    lock_version = User.find(user_id).lock_version.to_i
#    #####################################################################
#    #                             CASE 01
#    #  DELETE /users/:id with correct id
#    #####################################################################
#    pre_count = User.count
#    delete :destroy, {:format => 'json', :lock_version => lock_version,  :id => user_id }, {'user' => user }
#    post_count = User.count
#    assert_response :success
#    assert_equal(-1, post_count - pre_count)
#  end
  
  
  

end
  
  
