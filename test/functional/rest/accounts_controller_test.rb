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

require File.dirname(__FILE__) + '/../test_helper'
require 'rest/accounts_controller'

require 'json'
# assert_response status_code
# assert_redirect
# assert_redirect_to
# Re-raise errors caught by the controller.
class Rest::AccountsController; def rescue_action(e) raise e end; end


class AccountsControllerTest < Test::Unit::TestCase
  
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
    @controller   = Rest::AccountsController.new
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
  
  def test_accessing_irrelevant_item
    res_id = 3
    res_name = 'Account'
    user = User.find @db1_admin_user_id
    json = {:errors =>["#{res_name}[#{res_id}] does not belong to User[#{user.id}] (\"#{user.login}\")"]}.to_json
    get :show, {:format => 'json', :id => 3}, {'user' => user}
    assert_equal json, @response.body
  end
  

  
  def test_get_all
    # CASE 01: GET /accounts
    user = User.find @db1_admin_user_id
    ######################################################################
    #                           CASE 01
    #   GET /accounts
    ######################################################################
    json = Account.find(:all)
    get :index, {:format => 'json'}, {'user' => user}
    #assert_equal '', @response.body
    result = JSON.parse(@response.body)
    assert_response :success
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
    #total_records = Detail.count_by_sql "SELECT COUNT(*) FROM  #{table_name} WHERE #{conditions}"
    conditions = 'id=50'
    
    total_records = Account.count
    max_results = 3
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
    
    
    
    order_by = 'name'
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
    
    conditions = "country='Russia'"
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
    # CASE 01: GET /accounts/:id with all ok
    # CASE 02: GET /accounts/:id with wrong id
    user = User.find @db1_admin_user_id
    
    account = 1
    ######################################################################
    #                           CASE 01
    #   GET /accounts/id with all ok
    ######################################################################
    model = Account.find(account)
    get :show, {:format => 'json', :id => account}, {'user' => user}
    assert_response :success
    assert_similar model, @response.body    
    
    
    account = 79884 #1
    ######################################################################
    #                           CASE 02
    #   GET /accounts/id with wrong id
    ######################################################################
    json = {:errors => ["Account[#{account}] does not exists"]}.to_json
    get :show, {:format => 'json', :id => account}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body    
    #JSON.parse(json)
    
  
  end
  
  def test_post
    # CASE 01: POST /accounts with all ok
    # CASE 02: POST /accounts with resource missing
    # CASE 03: POST /accounts with resource but account_type missing
    # CASE 04: POST /accounts with resource but account_type wrong.
    user = User.find @db1_admin_user_id
    account = 
      {
        :account_type_url     => 'http://localhost:3000/account_types/1.json',
        :name                 => 'test_account',
        :street               =>  'I-8/2 Street 35',
        :zip_code             => '051000',
        :city                 => 'Islamabad',
        :country              => 'Pakistan',
        :status               => 'active',
        :end_date             => '2105-05-22',
#        :subscription_id      => 'PAK-98745',
#        :subscription_gateway => 'No Gateway',
        :vat_number           => 'asdfs',
#        :attachment_count     => 0
      }
      
    ###################################################################
    #                          CASE 01
    #    POST /accounts with all ok
    ###################################################################
    pre_count = Account.count
    post :create, {:format => 'json', :account => account.to_json}, {'user' => user}
    #assert_equal '', @response.body
    assert_response 201
    post_count = Account.count
    assert_equal 1, post_count - pre_count
    #assert_equal '', @response.body
    
    ###################################################################
    #                          CASE 02
    #    POST /accounts with resource missing
    ###################################################################
    json = {:errors => ['Provide account resource to be created/updated']}.to_json
    pre_count = Account.count
    post :create, {:format => 'json'}, {'user' => user}
    assert_response 400
    post_count = Account.count
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    
    account.delete :account_type_url
    ###################################################################
    #                          CASE 03
    #    POST /accounts with resource but without mention of account type id
    ###################################################################
    json = {:errors => ['Account type is not mentioend in account resource']}.to_json
    pre_count = Account.count
    post :create, {:format => 'json', :account => account.to_json},
      {'user' => user}
    assert_response 400
    post_count = Account.count
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    
    
    account[:account_type_url] = 'http://localhost:3000/account_types/19857.json'
    ###################################################################
    #                          CASE 04
    #    POST /accounts with resource but without mention of account type id
    ###################################################################
    json = {:errors => ["AccountType[19857] does not exists"]}.to_json
    pre_count = Account.count
    post :create, {:format => 'json', :account => account.to_json},
      {'user' => user}
    assert_response 404
    post_count = Account.count
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    
  end
  
  def test_put
    # CASE 01: GET an account, change its name and put it back.
    # CASE 02: PUT accounts/:id with wrong id
    # CASE 03: PUT accounts/:id with account resource missing
    user = User.find @db1_admin_user_id
    #####################################################################
    #                         CASE 01
    #   PUT /accounts
    #####################################################################
    
    account = JSON.parse(Account.find(1).to_json(:format => 'json'))
    
    account['name'] = 'TEST CHANGEOVER'
    
    put :update, {:format => 'json', :id => 1, :account => account.to_json},
      {'user' => user}
    model = Account.find(1)
    assert_response 200
    assert_similar model, @response.body
    #assert_equal '', @response.body
    
    # JUST TO CLEARE THE TEST
    account['url'] = 'http://www.myowndb.com/accounts/1454.json'
    #####################################################################
    #                         CASE 02
    #   PUT /accounts with wrong id
    #####################################################################
    json = {:errors => ["Account[1454] does not exists"]}.to_json
    put :update, {:format => 'json', :id => 1454, :account => account.to_json},
      {'user' => user}
    #assert_response 404
    assert_equal json, @response.body
    
    #####################################################################
    #                         CASE 03
    #   PUT /accounts with account resource missing
    #####################################################################
    json = {:errors => ["Provide account resource to be created/updated"]}.to_json
    put :update, {:format => 'json', :id => 1454}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    
  end
  
  def test_put_without_lock_version
    user = User.find @db1_admin_user_id
    account = JSON.parse(Account.find(1).to_json(:format => 'json'))
    
    account['name'] = 'TEST CHANGEOVER'
    account.delete('lock_version')
    
    put :update, {:format => 'json', :id => 1, :account => account.to_json},
      {'user' => user}
    json = {:errors => ['Provide lock_version for update/delete operations']}.to_json
    assert_response 400
    assert_equal json, @response.body
  end
  
  def test_get_and_put
    user = User.find @db1_admin_user_id
    
    get :show, {:format => 'json', :id => 1}, {'user' => user}
    account = JSON.parse(@response.body)
    
    account['name'] = 'GET AND PUT TEST'
    
    put :update, {:format => 'json', :id => 1, :account => account.to_json},
      {'user' => user}
    assert_response 200
    new_val = JSON.parse(@response.body)
    assert_equal account['name'], new_val['name']    
  end
  
  def test_get_and_put_conflict
    id = 1
    res_id = 78
    user = User.find @db1_admin_user_id
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource = JSON.parse(@response.body)
    
    resource['name'] = 'GET AND PUT TEST'
    resource['url'] = 'http://localhost:300/accounts/' + res_id.to_s + '.json'
    
    json = {:errors => ["Requested ID is #{id} and ID in resource is #{res_id}. Are you dispatching your resource at the right location?"]}.to_json
    put :update, {:format => 'json', :id => id, :account => resource.to_json},
      {'user' => user}
    assert_response 400
    assert_equal json, @response.body
  end
  
  def test_get_and_put_version_conflict
    user = User.find_by_id @db1_admin_user_id
    
    id = 1
    res_name = 'account'
    
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
    
    msg = 'Attempted to update a stale object'
    put :update, {:format => 'json', :id => id, res_name => resource2.to_json}, {'user' => user}
    assert_response 409
    assert_equal msg, JSON.parse(@response.body)['message']
    
    
    
    
  end
  
  
  def test_delete
    # CASE 01: DELETE /accounts/:id with all ok
    # CASE 02: DELETE /accounts/:id with wrong id
    user = User.find @db1_admin_user_id
    
    account = 1
    lock_version = Account.find(account).lock_version.to_i
    ####################################################################
    #                           CASE 01
    #  DELETE /accounts/:id with all ok                           
    ####################################################################
    pre_count = Account.count
    delete :destroy, {:format => 'json', :lock_version => lock_version, :id => account},
      {'user' => user}
    post_count = Account.count
    assert_response 200
    assert_equal 1, pre_count - post_count
    
  end
  
  def test_delete_with_wrong_account
    user = User.find(@db1_admin_user_id)
    account = 18787 #1
    lock_version = 7979
    ####################################################################
    #                           CASE 02
    #  DELETE /accounts/:id with wrong id
    ####################################################################
    pre_count = Account.count
    json = {:errors => ["Account[#{account}] does not exists"]}.to_json
    delete :destroy, {:format => 'json', :lock_version => lock_version, :id => account},
      {'user' => user}
    post_count = Account.count
    assert_response 404
    assert_equal 0, pre_count - post_count
    assert_equal json, @response.body
    
    
  end
  
  def test_delete_with_version_conflict
    # Get a resource
    # Get its lock version
    # modify resource
    # post it back
    user = User.find @db1_admin_user_id
    
    id = 1
    res_name = 'account'
    lock_version = nil
    klass = Account
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource = JSON.parse(@response.body)
    
    lock_version = resource['lock_version']
    
    # PUT it back
    put :update, {:format => 'json', res_name => resource.to_json, :id => id},
      {'user' => user}
    
    msg = 'Attempted to delete a stale object'
    pre_count = klass.count
    delete :destroy, {:format => 'json', :id => id, :lock_version => lock_version},
      {'user' => user}
    post_count = klass.count
    assert_response 409
    assert_equal 0, post_count - pre_count
    assert_equal msg, JSON.parse(@response.body)['message']
  end
  
  def test_delete_without_lock_version
    
    user = User.find @db1_admin_user_id
    
    account = 1
    #lock_version = Account.find(account).lock_version.to_i
    ####################################################################
    #                           CASE 01
    #  DELETE /accounts/:id with all ok                           
    ####################################################################
    pre_count = Account.count
    json = {:errors => ['Provide lock_version for update/delete operations']}.to_json
    delete :destroy, {:format => 'json', :id => account}, {'user' => user}
    post_count = Account.count
    assert_response 400
    assert_equal json, @response.body
    assert_equal 0, pre_count - post_count
    
    
  end

  

  
  

  
end
  
  
