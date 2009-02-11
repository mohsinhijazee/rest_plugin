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
require 'rest/detail_statuses_controller'

require 'json'
# assert_response status_code
# assert_redirect
# assert_redirect_to
# Re-raise errors caught by the controller.
class Rest::DetailStatusesController; def rescue_action(e) raise e end; end


class DetailStatusesControllerTest < Test::Unit::TestCase
  
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
            :detail_status, 
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
    @controller   = Rest::DetailStatusesController.new
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
    # CASE 01: GET /detail_statuses
    user = User.find @db1_admin_user_id
    ######################################################################
    #                           CASE 01
    #   GET /detail_statuses
    ######################################################################
    json = DetailStatus.find(:all)
    get :index, {:format => 'json'}, {'user' => user}
    assert_response :success
    result = JSON.parse(@response.body)
    assert_equal json.length, result['resources'].length
    
    
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
    table_name = 'data_types'
    conditions = 'database_id=6'
    #total_records = Detail.count_by_sql "SELECT COUNT(*) FROM  #{table_name} WHERE #{conditions}"
    conditions = 'id=50'
    
    total_records = DetailStatus.count
    max_results = 1
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
    assert_equal 1, result['resources'][0]['url'].chomp('.json')[/\d+$/].to_i
        
    conditions = "name='active'"
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
    # CASE 01: GET /detail_statuses/:id with all ok
    # CASE 02: GET /detail_statuses/:id with wrong id
    
    user = User.find @db1_admin_user_id
    
    status = 1
    ######################################################################
    #                           CASE 01
    #   GET /detail_statuses/:id with all ok
    ######################################################################
    model = DetailStatus.find(status)
    get :show, {:format => 'json', :id => status}, {'user' => user}
    assert_response :success
    assert_similar model  , @response.body    
    
    
    status = 79884 #1
    ######################################################################
    #                           CASE 02
    #   GET /detail_statuses/:id with wrong id
    ######################################################################
    json = {:errors => ["DetailStatus[#{status}] does not exists"]}.to_json
    get :show, {:format => 'json', :id => status}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body    
    #JSON.parse(json)
    
  
  end
  
  def test_post
    # CASE 01 POST /detail_status
    
    user = User.find @db1_admin_user_id
    ######################################################################
    #                           CASE 01
    #   POST /detail_status
    ######################################################################
    json = {:errors => ["Action 'create' not allowed on detail statuses"]}.to_json
    get :create, {:format => 'json'}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body    
    
  end
  
  def test_put
    # CASE 01 PUT /detail_status
    
    user = User.find @db1_admin_user_id
    ######################################################################
    #                           CASE 01
    #   PUT /account_types
    ######################################################################
    json = {:errors => ["Action 'update' not allowed on detail statuses"]}.to_json
    get :update, {:format => 'json'}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body    
    
  end
  
  def test_delete
    # CASE 01 DELETE /detail_status
    
    user = User.find @db1_admin_user_id
    ######################################################################
    #                           CASE 01
    #   DELETE /account_types
    ######################################################################
    json = {:errors => ["Action 'destroy' not allowed on detail statuses"]}.to_json
    get :destroy, {:format => 'json'}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body    
    
  end
  

  
end
  
  
