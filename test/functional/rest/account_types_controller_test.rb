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
require 'rest/account_types_controller'

require 'json'
# assert_response status_code
# assert_redirect
# assert_redirect_to
# Re-raise errors caught by the controller.
class Rest::AccountTypesController; def rescue_action(e) raise e end; end

# Make these methods public
#Rest::AccountTypesController.send(:public, :validate_rest_call)
#Rest::AccountTypesController.send(:public, :check_ids)
#Rest::AccountTypesController.send(:public, :params)

class AccountTypesControllerTest < Test::Unit::TestCase
  
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
    @controller   = Rest::AccountTypesController.new
    @request      = ActionController::TestRequest.new
    @response      = ActionController::TestResponse.new
    
    @db1_admin_user_id = 2
  end
  
  def test_without_login
    assert true
#    id = 1
#    get :show, {:format => 'json', :id => id}, {'user' => nil}
#    assert_response 401
#    json = %Q~{"errors": ["Please login to consume the REST API"]}~
#    assert_equal json, @response.body  
  end
  
  def test_get_all
    # CASE 01: GET /account_types
    user = User.find(@db1_admin_user_id)
    ######################################################################
    #                           CASE 01
    #   GET /account_types
    ######################################################################
    json = AccountType.find(:all)
    get :index, {:format => 'json'}, {'user' => user}
    assert_response :success
    result = JSON.parse(@response.body)
    
    assert_equal json.length, result['resources'].length
    
    #JSON.parse(json)
    
  end
  
  def test_get_all_with_pagination
    # CASE 01: Mention of start_index and max_results
    # CASE 02: Mention of Order by with direction
    # CASE 03: Mention of Order by without direction
    # CASE 04: Mention a condition also
    
    user = User.find_by_id(@db1_admin_user_id)
    
    parent_resource = :asdf
    parent_id = nil
    start_index = 0
    max_results = 3
    order_by = 'name'
    direction = 'DESC'
    table_name = 'details'
    conditions = 'database_id=6'
    total_records = Detail.count_by_sql "SELECT COUNT(*) FROM  #{table_name} WHERE #{conditions}"
    conditions = 'id=50'
    
    total_records = AccountType.count
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
    assert_equal 3, result['resources'].length
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
    result = JSON.parse result
    assert_equal max_results, result['resources'].length
    assert_equal 'asc', result['direction']
    
    conditions = "name='madb_account_type_free'"
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
    
    
  end
  
  def test_get_single
    # CASE 01: GET /account_types/:id with all ok
    # CASE 02: GET /account_types/:id with wrong id
    
    user = User.find(@db1_admin_user_id)
    
    account_type = 1
    ######################################################################
    #                           CASE 01
    #   GET /accounts/id with all ok
    ######################################################################
    model = AccountType.find(account_type)
    get :show, {:format => 'json', :id => account_type}, {'user' => user}
    assert_response :success
    assert_similar model, @response.body    
    
    
    account_type = 79884 #1
    ######################################################################
    #                           CASE 02
    #   GET /accounts/id with wrong id
    ######################################################################
    json = {:errors => ["AccountType[#{account_type}] does not exists"]}.to_json
    get :show, {:format => 'json', :id => account_type}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body    
    #JSON.parse(json)
    
  
  end
  
  def test_post
    # CASE 01 POST /account_types with all ok
    # CASE 01 POST /account_types without resource
    user = User.find(@db1_admin_user_id)
    account_type = 
      {
        :name => "testtype",
        :active => true,
        :free => false,
        :number_of_users => :madb_unlimited,
        :number_of_databases => 100,
        :monthly_fee => 100.85,
        :maximum_file_size => 6524187,
        :maximum_monthly_file_transfer => 4455757,
        :maximum_attachment_number => 78
        
      }
      
    
    ######################################################################
    #                           CASE 01
    #   POST /account_types
    ######################################################################
    pre_count = AccountType.count
    get :create, {:format => 'json', :account_type => account_type.to_json}, {'user' => user}
    post_count = AccountType.count
    assert_response 201
    assert_equal 1, post_count - pre_count
    #assert_equal '', @response.body
    
    
    ######################################################################
    #                           CASE 02
    #   POST /account_types without resource
    ######################################################################
    json = {:errors => ['Provide the account type resource to be created/updated']}.to_json
    pre_count = AccountType.count
    get :create, {:format => 'json'}, {'user' => user}
    post_count = AccountType.count
    assert_response 400
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    
  end
  
  def test_put
    # CASE 01 PUT /account_types with all ok
    # CASE 02 PUT /account_types with missing resource
    # CASE 03 PUT /account_types with wrong id
    
    user = User.find(@db1_admin_user_id)
    # CASE 01 POST /account_types
    
    account_type = 
      {
        :name => "testtype",
        
      }
      
     id = 1
    ######################################################################
    #                           CASE 01
    #   PUT /account_types
    ######################################################################
    
    pre_count = AccountType.count
    get :update , {:format => 'json', :id => id, :account_type => account_type.to_json}, {'user' => user}
    model = AccountType.find(id)
    post_count = AccountType.count
    assert_response 200
    assert_equal 0, post_count - pre_count
    assert_similar model, @response.body
    assert_equal AccountType.find(id).name, account_type[:name]
    
    #assert_equal '', @response.body
    
    
    ######################################################################
    #                           CASE 02
    #   PUT /account_types without resource
    ######################################################################
    json = {:errors => ['Provide the account type resource to be created/updated']}.to_json
    pre_count = AccountType.count
    get :create, {:format => 'json', :id => id}, {'user' => user}
    post_count = AccountType.count
    assert_response 400
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    
    id = 457
    ######################################################################
    #                           CASE 03
    #   PUT /account_types with wrong id
    ######################################################################
    json = {:errors => ["AccountType[#{id}] does not exists"]}.to_json
    pre_count = AccountType.count
    get :create, {:format => 'json', :id => id, :account_type => account_type.to_json}, {'user' => user}
    post_count = AccountType.count
    assert_response 404
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    
     
    
  end
  
  def test_get_and_put
    
    user = User.find(@db1_admin_user_id)
    
    get :show, {:format => 'json', :id => 1}, {'user' => user}
    account = JSON.parse(@response.body)
    
    account['name'] = 'GET AND PUT TEST'
    
    put :update, {:format => 'json', :id => 1, :account_type => account.to_json}, {'user' => user}
    assert_response 200
    new_val = JSON.parse(@response.body)
    assert_equal account['name'], new_val['name']
    
    
  end
  
  def test_get_and_put_conflict
    user = User.find(@db1_admin_user_id)
    
    get :show, {:format => 'json', :id => 1}, {'user' => user}
    account = JSON.parse(@response.body)
    
    account['name'] = 'GET AND PUT TEST'
    account['url'] = 'http://localhost:300/account_types/78.json'
    
    json = {:errors => ["Requested ID is #{1} and ID in resource is #{78}. Are you dispatching your resource at the right location?"]}.to_json
    put :update, {:format => 'json', :id => 1, :account_type => account.to_json}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
  end
  
  def test_delete
    # CASE 01 DELETE /account_types
    user = User.find(@db1_admin_user_id)
    
    id = 1
    ######################################################################
    #                           CASE 01
    #   DELETE  /account_types/:id with all sok
    ######################################################################
    pre_count = AccountType.count
    get :destroy, {:format => 'json', :id => id}, {'user' => user}
    post_count = AccountType.count
    assert_response 200
    assert_equal(-1, post_count - pre_count)
    
    id = 17987
    ######################################################################
    #                           CASE 01
    #   DELETE  /account_types/:id with all sok
    ######################################################################
    json = {:errors => ["AccountType[#{id}] does not exists"]}.to_json
    pre_count = AccountType.count
    get :destroy, {:format => 'json', :id => id}, {'user' => user}
    post_count = AccountType.count
    assert_response 404
    assert_equal json, @response.body    
    assert_equal(0, post_count - pre_count)
    
  end
  
end
  
  
