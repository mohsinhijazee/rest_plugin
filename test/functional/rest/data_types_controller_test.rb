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
require 'rest/data_types_controller'

require 'json'
# assert_response status_code
# assert_redirect
# assert_redirect_to
# Re-raise errors caught by the controller.
class Rest::DataTypesController; def rescue_action(e) raise e end; end


class DataTypesControllerTest < Test::Unit::TestCase
  
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
    @controller   = Rest::DataTypesController.new
    @request      = ActionController::TestRequest.new
    @response      = ActionController::TestResponse.new
    
    @db1_admin_user_id = 2
  end
  
  def test_without_login
    # FIXME: Will be done after REST auth
    assert true
#    id = 1
#    get :show, {:format => 'json', :id => id}, {'user' => nil}
#    assert_response 401
#    json = %Q~{"errors": ["Please login to consume the REST API"]}~
#    assert_equal json, @response.body  
  end
  
  def test_get_all
    user = User.find @db1_admin_user_id
    
    
    json = DataType.find(:all)
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
    
    total_records = DataType.count
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

    result = JSON.parse(result)

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

    result = JSON.parse(result)

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

    result = JSON.parse(result)

    assert_equal max_results, result['resources'].length
    assert_equal 'asc', result['direction']
    
    conditions = "class_name='SimpleDetailValue'"
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

    result = JSON.parse(result)

    assert_equal 1, result['resources'].length
    assert_equal 'asc', result['direction']
   
  end
  
  def test_get_single
    # CASE 01: GET /datatypes/:id with correct id
    # CASE 02: GET /datatypes/:id with wrong id
  
    user = User.find @db1_admin_user_id
    
    datatype = 1
    ###################################################################
    #                          CASE 01
    #  GET /datatypes/:id with correct id                         
    ###################################################################
    model = DataType.find(datatype)
    get :show, {:format => 'json', :id => datatype}, {'user' => user}
    assert_response :success
    assert_similar model, @response.body
    
    datatype = 97 #1
    ###################################################################
    #                          CASE 02
    #  GET /datatypes/:id with wrong id
    ###################################################################
    json = {:errors => ["Datatype[#{datatype}] does not exists"]}.to_json
    get :show, {:format => 'json', :id => datatype}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    
  end
  
  def test_post
    user = User.find(@db1_admin_user_id)
    json = {:errors => ["Action 'create' not allowed on datatypes"]}.to_json
    post :create, {:format => 'json', :data_type => ''}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
  end
  
  def test_put
    user = User.find(@db1_admin_user_id)
    json = {:errors => ["Action 'update' not allowed on datatypes"]}.to_json
    put :update, {:format => 'json', :id => 4, :data_type => ''}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
  end
  
  def test_delete
    user = User.find(@db1_admin_user_id)
    json = {:errors => ["Action 'destroy' not allowed on datatypes"]}.to_json
    post :destroy, {:format => 'json', :id => 10}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
  end
  
  

  
end
  
  
