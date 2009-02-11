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
require 'rest/instances_controller'

#FIXME: Tests of the controller should be executed indivisually otherwise
# test_get_all_with_pagination will not work maybe due to transactions issue
# This test should be executed in isolation like this:
# mohsin@tercel:~ ruby instances_controller_test.rb -n test_get_all_with_pagination


# 
# assert_response status_code
# assert_redirect
# assert_redirect_to
# Re-raise errors caught by the controller.
class Rest::InstancesController; def rescue_action(e) raise e end; end

class InstancesControllerTest < Test::Unit::TestCase
self.use_transactional_fixtures = false
  
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
    @controller   = Rest::InstancesController.new
    @request      = ActionController::TestRequest.new
    @response      = ActionController::TestResponse.new
    
    @db1_admin_user_id = 2
    @db2_admin_user_id = 1000003
  end
  
  def test_without_login
    #FIXME: Will be rewritten after implementaion of REST auth
#    id = 200
#    get :show, {:format => 'json', :id => id}, {'user' => nil}
#    assert_response 401
#    json = %Q~{"errors": ["Please login to consume the REST API"]}~
#    assert_equal json, @response.body  

  end
  
  def test_accessing_irrelevant_item
    res_id = 25
    res_name = 'Instance'
    user = User.find @db1_admin_user_id
    json = {:errors =>["#{res_name}[#{res_id}] does not belong to User[#{user.id}] (\"#{user.login}\")"]}.to_json
    get :show, {:format => 'json', :id => res_id}, {'user' => user}
    assert_equal json, @response.body
    
    entity = 7
    res_id = 25
    res_name = 'Entity'
    user = User.find @db1_admin_user_id
    json = {:errors =>["#{res_name}[#{entity}] does not belong to User[#{user.id}] (\"#{user.login}\")"]}.to_json
    get :show, {:format => 'json', :entity_id => entity, :id => res_id}, {'user' => user}
    assert_equal json, @response.body
  end
  
  def test_get_all
    # CASE 01: GET /entities/instances with all ok
    # CASE 02: GET /entities/instances with wrong entity
    user = User.find @db1_admin_user_id
    
    
    entity = 100
    ###################################################################
    #                           CASE 01
    #   GET /entities/instances
    ###################################################################
    get :index, {:format => 'json', #'start-index' => 0, 'max-results' => 1,
      :entity_id => entity}, {'user' => user}
    #assert_equal '', @response.body
    assert_response :success
    
    JSON.parse(@response.body)
    
    entity = 979774 #100
    ###################################################################
    #                           CASE 01
    #   GET /entities/instances
    ###################################################################
    get :index, {:format => 'json', #'start-index' => 0, 'max-results' => 1,
      :entity_id => entity}, {'user' => user}
    json = {:errors => ["Entity[#{entity}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body
    JSON.parse(@response.body)
  end
  
  #FIXME: This test fails due to transactions. Only those assertions fail
  # which mention a condtion becuase the underlying database does not contain
  # that data. This test should be run in isolation liek this:
  # mohsin@tercel:~ ruby instances_controller_test.rb -n test_get_all_with_pagination

  def test_get_all_with_pagination
    # CASE 01: Mention of start_index and max_results
    # CASE 02: Mention of Order by with direction
    # CASE 03: Mention of Order by without direction
    # CASE 04: Mention a condition also
    # CASE 05: Getting only details of an entity
    
    user = User.find_by_id(@db1_admin_user_id)
    
    parent_resource = :entity_id
    parent_id = 100
    start_index = 10
    max_results = 10
    order_by = 'name'
    direction = 'DESC'
    table_name = 'instances'
    conditions = 'database_id=6'
    total_records = 0
    conditions = 'id=50'
    
    start_index = 0
    max_results = 1
    conditions = "entity_id=#{parent_id}"
    total_records = Instance.count_by_sql "SELECT COUNT(*) FROM  #{table_name} WHERE #{conditions}"
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
    assert_equal total_records, result['total_resources'].to_i
    
    
    order_by = 'name'
    direction = 'desc'
    start_index = 0
    max_results = 10
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

    assert_equal 2, result['resources'].length
    assert_equal 'desc', result['direction']
    #assert_equal 201, result['resources'][0]['url'].chomp('.json')[/\d+$/].to_i
    
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

    result = JSON.parse(result)

    assert_equal 2, result['resources'].length
    assert_equal 'asc', result['direction']
    #assert_equal 200, result['resources'][0]['url'].chomp('.json')[/\d+$/].to_i
    
# FIXME: Following two tests always fail either in isolation or
# in a complete execution of the tests due to disabling transactional fixtuers 
#    start_index = 0
#    max_results = 10
#    order_by = 'name'
#    conditions = "category='Fiction'"
#    #########################################################
#    #                        CASE 04
#    #        Mention of order by specifying condition
#    #########################################################
#    get :index, {
#      parent_resource => parent_id,
#      :format => 'json', 
#      :start_index => start_index, 
#      :max_results => max_results,
#      :order_by => order_by,
#      :conditions => conditions
#    },
#      {'user' => user}
#    #assert_equal '', @response.body
#    assert_response 200
#    result = @response.body
#    result = JSON.parse result
#    assert_equal 1, result['resources'].length
#    assert_equal 'asc', result['direction']
#    #assert_equal 201, result['resources'][0]['url'].chomp('.json')[/\d+$/].to_i
#    
#    conditions = "category='Computer Science' AND name='Compiler, Principles, Tools and Techniques'"
#    #########################################################
#    #                        CASE 05
#    #        Mention of compound conditions
#    #########################################################
#    get :index, {
#      parent_resource => parent_id,
#      :format => 'json', 
#      :start_index => start_index, 
#      :max_results => max_results,
#      :order_by => order_by,
#      :conditions => conditions
#    },
#      {'user' => user}
#    assert_equal '', @response.body
#    assert_response 200
#    result = @response.body
#    result = JSON.parse result
#    assert_equal 1, result['resources'].length
#    assert_equal 'asc', result['direction']
#    assert_equal 200, result['resources'][0]['url'].chomp('.json')[/\d+$/].to_i
    
    
  end
  
  def test_get_single
    # CASE 01: GET /entities/instances/:id with all ok
    # CASE 02: GET /entities/instances/:id with instance does not exists
    # CASE 03: GET /entities/instances/:id with entity does not exists
    # CASE 04: GET /entities/instances/:id with both unrelated
    # CASE 05: GET /instances/:id with all ok
    # CASE 06: GET /instances/:id with wrong id
    
    
    user = User.find @db1_admin_user_id
    
    entity = 100
    instance = 200
    #####################################################################
    #                            CASE 01
    #  GET /entities/instances/:id with all ok                          
    #####################################################################
    #json = Instance.find(instance).to_json(:format => 'json')
    get :show, {:format => 'json', :entity_id => entity, :id => instance}, {'user' => user}
    assert_response :success
    #assert_equal json, @response.body
    #JSON.parse(json)
    JSON.parse(@response.body)
    
    entity = 100
    instance = 9879 #200
    #####################################################################
    #                            CASE 02
    #  GET /entities/instances/:id with wrong instance
    #####################################################################
    json = {:errors => ["Instance[#{instance}] does not exists"]}.to_json
    get :show, {:format => 'json', :entity_id => entity, :id => instance}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    #JSON.parse(json)
    
    entity = 7979741 #100
    instance = 200
    #####################################################################
    #                            CASE 03
    #  GET /entities/instances/:id with wrong entity
    #####################################################################
    json = {:errors => ["Entity[#{entity}] does not exists"]}.to_json
    get :show, {:format => 'json', :entity_id => entity, :id => instance}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    #JSON.parse(json)
    
    entity = 100
    instance = 70 #200
    #####################################################################
    #                            CASE 04
    #  GET /entities/instances/:id with both irrelevant
    #####################################################################
    json = {:errors => ["Instance[#{instance}] does not belong to Entity[#{entity}]"]}.to_json
    get :show, {:format => 'json', :entity_id => entity, :id => instance}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    #JSON.parse(json)
    
    entity = 100
    instance = 200
    #####################################################################
    #                            CASE 05
    #  GET /instances/:id with all ok                          
    #####################################################################
    #json = Instance.find(instance).to_json(:format => 'json')
    get :show, {:format => 'json', :id => instance}, {'user' => user}
    assert_response :success
    #assert_equal json, @response.body
    JSON.parse(json)
    
    entity = 100
    instance = 9879 #200
    #####################################################################
    #                            CASE 05
    #  GET /instances/:id with wrong instance
    #####################################################################
    json = {:errors => ["Instance[#{instance}] does not exists"]}.to_json
    get :show, {:format => 'json', :id => instance}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    #JSON.parse(json)
    
  end
  
  def test_post
    # CASE 01: POST /entities/instances with all ok
    # CASE 02: POST /entities/instance with missing instance resource
    
    user = User.find(@db1_admin_user_id)
    
    entity = 100

    instances = 
    [
      {
        "Name" =>               ["Dummy Book", "Instant Book", "Cook Book"],
        "Description" =>        ["A Dummp book not yet published"],
        "Published" =>          ["1919/12/12 00:00:00 +0500", "2018/02/06 00:00:00 +0500"],
        "Pages" =>              [1284],
        "Category" =>           [1003,1007],
        "Email" =>              ["abc@email.com", "def@email.com"],
        "Website" =>            ["http://www.ali.com", "http://www.raph.com"]
      },
      
      {
        :Name =>               ["BookA_1", "BookA_41", "BookA_19"],
        :Description =>        ["Book A with three names"],
        :Published =>          ["1979/12/02 00:00:00 +0500", "1988/02/06 00:00:00 +0500"],
        :Pages =>              [112],
        :Category =>           [1004,1005,1006],
        :Email =>              ["book21@email.com", "booka1@email.com"],
        :Website =>            ["http://www.ali.com", "http://www.raph.com"]
      }
    ]
    
    json = instances.to_json
    
    #######################################################################
    #                          CASE 01
    #  POST /entities/instances with all ok                         
    #######################################################################
    
#    json = %Q~
#[
#  {
#    "Name":               ["Dummy Book", "Instant Book", "Cook Book"],
#    "Description":        ["A Dummp book not yet published"],
#    "Published":          ["1919/12/12 00:00:00 +0500", "2018/02/06 00:00:00 +0500"],
#    "Pages":              [1284],
#    "Category":           [1003,1007],
#    "Email":              ["abc@email.com", "def@email.com"],
#    "Website":            ["http://www.ali.com", "http://www.raph.com"]
#  },
#  {
#    "Name":               ["BookA_1", "BookA_41", "BookA_19"],
#    "Description":        ["Book A with three names"],
#    "Published"K          ["1979/12-/2 00:00:00 +0500", "1988/02/6 00:00:00 +0500"],
#    "Pages":              [112],
#    "Category":           [1004,1005,1006],
#    "Email":              ["book21@email.com", "booka1@email.com"],
#    "Website":            ["http://www.ali.com", "http://www.raph.com"]
#  }
#]
#~

    pre_instance_count = Instance.count
    pre_detail_count = DetailValue.count
    pre_integer_count = IntegerDetailValue.count
    pre_date_count = DateDetailValue.count
    pre_ddl_count = DdlDetailValue.count
    
    post :create, {:format => 'json', :entity_id => entity, :instance => json},
      {'user' => user}
    
    #assert_equal '', @response.body
    
    assert_response 201
#    
    post_instance_count = Instance.count
    post_detail_count = DetailValue.count
    post_integer_count = IntegerDetailValue.count
    post_date_count = DateDetailValue.count
    post_ddl_count = DdlDetailValue.count
#    
#    # 2 instances created
    assert_equal 2, post_instance_count-pre_instance_count
#    # 16 detail values created:
#    # 6 Names + 2 Descriptions + 4 Emails + 4 WebUrls
    assert_equal 16, post_detail_count-pre_detail_count
#    # 2 integer values created
    assert_equal 2, post_integer_count-pre_integer_count
#    # 4 detail values
    assert_equal 4, post_date_count-pre_date_count
#    # 5 ddl values
    assert_equal 5, post_ddl_count-pre_ddl_count
    
    #######################################################################
    #                          CASE 02
    #  POST /entities/instances with missing resource
    #######################################################################
    json = {:errors => ['Provide the instances to be created in instances parameter of request']}.to_json
    post :create, {:format => 'json', :entity_id => entity},
      {'user' => user}
    assert_response 400
    assert_equal json, @response.body
  end
  
  
  
  def test_post_alone
    # CASE 01: POST /instances where entity_id is part of the resource
    # CASE 02: POST /instances where entity_id is NOT part of the resource
    # CASE 03: POST /instances where entity_id is part of the resource but is wrong
    
    user = User.find(@db1_admin_user_id)
    
    entity = 100

    instances = 
    [
      {
        :entity_id => entity,
        "Name" =>               ["Dummy Book", "Instant Book", "Cook Book"],
        "Description" =>        ["A Dummp book not yet published"],
        "Published" =>          ["1919/12/12 00:00:00 +0500", "2018/02/06 00:00:00 +0500"],
        "Pages" =>              [1284],
        "Category" =>           [1003,1007],
        "Email" =>              ["abc@email.com", "def@email.com"],
        "Website" =>            ["http://www.ali.com", "http://www.raph.com"]
      },
      
      {
        :Name =>               ["BookA_1", "BookA_41", "BookA_19"],
        :Description =>        ["Book A with three names"],
        :Published =>          ["1979/12/02 00:00:00 +0500", "1988/02/06 00:00:00 +0500"],
        :Pages =>              [112],
        :Category =>           [1004,1005,1006],
        :Email =>              ["book21@email.com", "booka1@email.com"],
        :Website =>            ["http://www.ali.com", "http://www.raph.com"]
      }
    ]
    
    ######################################################################
    #                          CASE 01
    #  POST /instances where entity_id is part of the resource
    ######################################################################
    pre_instance_count = Instance.count
    pre_detail_count = DetailValue.count
    pre_integer_count = IntegerDetailValue.count
    pre_date_count = DateDetailValue.count
    pre_ddl_count = DdlDetailValue.count
    
    post :create, {:format => 'json',  :instance => instances.to_json},
      {'user' => user}
    

    #assert_equal '', @response.body
    assert_response 201
    
    post_instance_count = Instance.count
    post_detail_count = DetailValue.count
    post_integer_count = IntegerDetailValue.count
    post_date_count = DateDetailValue.count
    post_ddl_count = DdlDetailValue.count
    
    # 2 instances created
    assert_equal 2, post_instance_count-pre_instance_count
    # 16 detail values created:
    # 6 Names + 2 Descriptions + 4 Emails + 4 WebUrls
    assert_equal 16, post_detail_count-pre_detail_count
    # 2 integer values created
    assert_equal 2, post_integer_count-pre_integer_count
    # 4 detail values
    assert_equal 4, post_date_count-pre_date_count
    # 5 ddl values
    assert_equal 5, post_ddl_count-pre_ddl_count
    
    instances[0].delete :entity_id
    ######################################################################
    #                          CASE 02
    #  POST /instances where entity_id is NOT part of the resource
    ######################################################################
    msg = "Provide the entity of the instance to be created either as a "
    msg += "field of the first instance to be created or make a nested call "
    msg += "POST /entities/:entity_id/instances"
    json = {:errors => [msg]}.to_json
    post :create, {:format => 'json',  :instance => instances.to_json},
      {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    
    instances[0][:entity_id] = 798797
    ######################################################################
    #                          CASE 03
    #  POST /instances where entity_id is part of the resource and is WRONG
    ######################################################################
    json = {:errors => ["Entity[798797] does not exists"]}.to_json
    post :create, {:format => 'json',  :instance => instances.to_json},
      {'user' => user}
    assert_equal json, @response.body
    assert_response 404
    assert_equal json, @response.body
  end
  
  def test_post_single_instance
        user = User.find(@db1_admin_user_id)
    
    entity = 100

    instances =   
      {
        :entity_id => entity,
        :Name =>               ["BookA_1", "BookA_41", "BookA_19"],
        :Description =>        ["Book A with three names"],
        :Published =>          ["1979/12/02 00:00:00 +0500", "1988/02/06 00:00:00 +0500"],
        :Pages =>              [112],
        :Category =>           [1004,1005,1006],
        :Email =>              ["book21@email.com", "booka1@email.com"],
        :Website =>            ["http://www.ali.com", "http://www.raph.com"]
      }
    
    
    ######################################################################
    #                          CASE 01
    #  POST /instances where entity_id is part of the resource
    ######################################################################
    pre_instance_count = Instance.count
    pre_detail_count = DetailValue.count
    pre_integer_count = IntegerDetailValue.count
    pre_date_count = DateDetailValue.count
    pre_ddl_count = DdlDetailValue.count
    
    post :create, {:format => 'json',  :instance => instances.to_json},
      {'user' => user}
    

    #assert_equal '', @response.body
    assert_response 201
    
    post_instance_count = Instance.count
    post_detail_count = DetailValue.count
    post_integer_count = IntegerDetailValue.count
    post_date_count = DateDetailValue.count
    post_ddl_count = DdlDetailValue.count
    
    # 2 instances created
    assert_equal 1, post_instance_count-pre_instance_count
    # 16 detail values created:
    # 6 Names + 2 Descriptions + 4 Emails + 4 WebUrls
    assert_equal 8, post_detail_count-pre_detail_count
    # 2 integer values created
    assert_equal 1, post_integer_count-pre_integer_count
    # 4 detail values
    assert_equal 2, post_date_count-pre_date_count
    # 5 ddl values
    assert_equal 3, post_ddl_count-pre_ddl_count
  end
  
  def test_post_with_value_limits
    # CASE 01: POST /entities/instances with all ok
    # CASE 02: POST /entities/instance with missing instance resource
    
    
    user = User.find(@db1_admin_user_id)
    
    entity = 100

    instances = 
    [
      {
        "Name" =>               ["Dummy Book", "Instant Book", "Cook Book"],
        "Description" =>        ["A Dummp book not yet published"],
        "Published" =>          ["1919/12/12 00:00:00 +0500", "2018/02/06 00:00:00 +0500"],
        "Pages" =>              [1284, 23, 34],
        "Category" =>           [1003,1007],
        "Email" =>              ["abc@email.com", "def@email.com"],
        "Website" =>            ["http://www.ali.com", "http://www.raph.com"]
      },
      
      {
        :Name =>               ["BookA_1", "BookA_41", "BookA_19"],
        :Description =>        ["Book A with three names"],
        :Published =>          ["1979/12/02 00:00:00 +0500", "1988/02/06 00:00:00 +0500"],
        :Pages =>              [112, 45,45,1],
        :Category =>           [1004,1005,1006],
        :Email =>              ["book21@email.com", "booka1@email.com"],
        :Website =>            ["http://www.ali.com", "http://www.raph.com"]
      }
    ]
    
    pre_count = Instance.count
    json = "Validation failed: Pages Pages[77] of Books[100] cannot have more then 1 values"

    post :create, {:format => 'json', :entity_id => entity, :instance => instances.to_json},
      {'user' => user}

    response_body = JSON.parse(@response.body)['message']

    post_count = Instance.count
    assert_equal 0, post_count - pre_count
    assert_equal json, response_body
  end
  
  def test_post_with_missing_details
    user = User.find(@db1_admin_user_id)
    
    entity = 100

    instances =   {
#        "Name" =>               ["Dummy Book", "Instant Book", "Cook Book"],
#        "Description" =>        ["A Dummp book not yet published"],
        "Published" =>          ["1919/12/12 00:00:00 +0500", "2018/02/06 00:00:00 +0500"],
#        "Pages" =>              [1284],
#        "Category" =>           [1003,1007],
        "Email" =>              ["abc@email.com", "def@email.com"],
#        "Website" =>            ["http://www.ali.com", "http://www.raph.com"]
      }
      

    
    #json = instances.to_json
    
    #######################################################################
    #                          CASE 01
    #  POST /entities/instances with all ok                         
    #######################################################################
    pre_count = Instance.count
    pre_detail = DetailValue.count
    pre_date = DateDetailValue.count
    post :create, {:format => 'json', :entity_id => entity, :instance => instances.to_json},
      {'user' => user}
    post_count = Instance.count
    post_detail = DetailValue.count
    post_date = DateDetailValue.count
    
    assert_response 201
    
    assert_equal 1, post_count - pre_count
    assert_equal 2, post_detail - pre_detail
    assert_equal 2, post_date - pre_date
    

  end
  
  def test_post_with_no_details
    
    user = User.find(@db1_admin_user_id)
    
    entity = 100

    instances =   {
#        "Name" =>               ["Dummy Book", "Instant Book", "Cook Book"],
#        "Description" =>        ["A Dummp book not yet published"],
#        "Published" =>          ["1919/12/12 00:00:00 +0500", "2018/02/06 00:00:00 +0500"],
#        "Pages" =>              [1284],
#        "Category" =>           [1003,1007],
#        "Email" =>              ["abc@email.com", "def@email.com"],
#        "Website" =>            ["http://www.ali.com", "http://www.raph.com"]
      }
      

    
    
    
    #######################################################################
    #                          CASE 01
    #  POST /entities/instances with all ok                         
    #######################################################################
    pre_count = Instance.count
    json = "Instance must mention at least one detail value to be created/updated"
    post :create, {:format => 'json', :entity_id => entity, :instance => instances.to_json},
      {'user' => user}
    
    post_count = Instance.count
    #assert_equal '', @response.body
    response_body = JSON.parse(@response.body)['errors'][0]
    assert_response 400
    assert_equal 0, post_count - pre_count
    assert_equal json, response_body
    
  end
  
  def test_post_with_wrong_details

    user = User.find(@db1_admin_user_id)
    
    entity = 100

    instances =   {
        "Name" =>               ["Dummy Book", "Instant Book", "Cook Book"],
        "Description" =>        ["A Dummp book not yet published"],
        "Published" =>          ["1919/12/12 00:00:00 +0500", "2018/02/06 00:00:00 +0500"],
        "Pages" =>              [1284],
        "Category" =>           [1003,1007],
        "Email" =>              ["abc@email.com", "def@email.com"],
        "Website" =>            ["http://www.ali.com", "http://www.raph.com"],
        "BloodGroup" => [47],
        "WrongField" => [478],
      }
      

    
    #json = instances.to_json
    
    #######################################################################
    #                          CASE 01
    #  POST /entities/instances with all ok                         
    #######################################################################
    #json = {:errors => ['Details Missing: [Description, Email, Published]']}.to_json
    post :create, {:format => 'json', :entity_id => entity, :instance => instances.to_json},
      {'user' => user}
    
    assert_response 201
    #assert_equal 'asdf', @response.body    

  end
  
  def test_post_with_special_characters
    # This test first creates two instances with special characters
    # and then checks for each of them whether any JSON error
    # or not
    user = User.find(@db1_admin_user_id)
    
    entity = 100

    instances = 
    [
      {
        "Name" =>               ["Dummy Book", "Instant Book", "Cook Book"],
        "Description" =>        ['<a href="www.google.com">google</a>'],
        "Published" =>          ["1919/12/12 00:00:00 +0500", "2018/02/06 00:00:00 +0500"],
        "Pages" =>              [1284],
        "Category" =>           [1003,1007],
        "Email" =>              ["abc@email.com", "def@email.com"],
        "Website" =>            ["http://www.ali.com", "http://www.raph.com"]
      },
      
      {
        :Name =>               ["BookA_1", "BookA_41", "BookA_19"],
        :Description =>        ['<html><head><title>A Book</title></head><body onLoad="asdf()">Bold</body></html>'],
        :Published =>          ["1979/12/02 00:00:00 +0500", "1988/02/06 00:00:00 +0500"],
        :Pages =>              [112],
        :Category =>           [1004,1005,1006],
        :Email =>              ["book21@email.com", "booka1@email.com"],
        :Website =>            ["http://www.ali.com", "http://www.raph.com"]
      }
    ]
    
    json = instances.to_json
    
    post :create, {:entity_id => entity,
                    :format => 'json',
                    :instance => json },
                    {'user' => user}
    
    #assert_equal '', @response.body
    assert_response 201
    
    
    get :show, {:id => 202, :format => 'json'}, {'user' => user}
    #assert_equal '', @response.body
    assert_response 200
    json = JSON.parse @response.body
    
    get :show, {:id => 203, :format => 'json'}, {'user' => user}
    assert_response 200
    json = JSON.parse @response.body
    #assert_equal '', json
    
    
    
  end
  
  def test_post_with_file_upload
    # CASE 01: POST /entities/instances/ with all ok
    # CASE 02: POST /entities/instances/ where file is not provided
    
    user = User.find(@db1_admin_user_id)
    
    
    ########################################################################
    #                            CASE 01
    #  CASE 01: POST /entities/instances/ with all ok
    ########################################################################
    entity = 101
    instance = 
      {
        :Name => ['Mohsin'],
        :Picture => ['picFile']      
    }
    
    pre_instance = Instance.count
    pre_detail_value = DetailValue.count
    post :create, 
      {
        :format => 'json', 
        :entity_id => entity,
        :instance => instance.to_json,
        :picFile => fixture_file_upload('/files/logo-Ubuntu.png', 'image/png', :binary)
      },
      {'user' => user}
    
    post_instance = Instance.count
    post_detail_value = DetailValue.count
    
    #assert_response '', @response.body
    
    assert_response 201
    assert_equal 1, post_instance - pre_instance
    assert_equal 2, post_detail_value - pre_detail_value
    
    #assert_response '', @response.body
    
#    get :show, {:id => 202}, {'user' => user}
#    assert_response 200
#    json = @response.body
##    assert_equal '', json
#     h = JSON.parse json
#    assert_equal h, ''
    
    
    ########################################################################
    #                            CASE 02
    #  CASE 01: POST /entities/instances/ with file missing
    ########################################################################
    entity = 101
    instance = 
      {
        :Name => ['Mohsin'],
        :Picture => ['picFile']      
    }
    
    pre_instance = Instance.count
    pre_detail_value = DetailValue.count
    post :create, 
      {
        :format => 'json', 
        :entity_id => entity,
        :instance => instance.to_json
        #:picFile => fixture_file_upload('/files/logo-Ubuntu.png', 'image/png', :binary)
      },
      {'user' => user}
    json = "Detail 'Picture' mentions 'picFile' to contain file attachment which is not provided"
    post_instance = Instance.count
    post_detail_value = DetailValue.count
    

    response_body = JSON.parse(@response.body)['message']

    assert_response 400
    assert_equal 0, post_instance - pre_instance
    assert_equal 0, post_detail_value - pre_detail_value
    
    assert_equal json, response_body
    
    
    
  end
  
  
  def test_put
    # CASE 01: POST /instances/:id with all ok
    # CASE 02: POST /instances/:id with wrong id
    user = User.find @db1_admin_user_id
    
    instance = 200
    name = 1200
    description = 1202
    resource =  
      {
        :lock_version => Instance.find(instance).lock_version.to_i, 
        :Name => [
                    {
                      :id => name, 
                      :lock_version => DetailValue.find(name).lock_version.to_i,
                      :value => "WAS COMPILER!"
                    }, 
                    {:value => "GREEN OLD BOOK"}
                  ], 
                  
        :Description => [
                            {
                              :id => 1202, 
                              :lock_version => DetailValue.find(description).lock_version.to_i,
                              :value => "What can we say on this????"
                              
                              }
                         ]
      }
      
    #######################################################################
    #                             CASE 01
    #  PUT /instances/:id with all ok
    #######################################################################
    pre_count = DetailValue.count
    put :update, {:format => 'json', :id => instance, :instance => resource.to_json}, {'user' => user}
    post_count = DetailValue.count
    #json = Instance.find(instance).to_json(:format => 'json')
    assert_response :success
    #assert_equal json, @response.body
    assert_equal 1, post_count - pre_count
    assert_equal "WAS COMPILER!", DetailValue.find(1200).value
    assert_equal "What can we say on this????", DetailValue.find(1202).value
    #JSON.parse(json)
    #assert_equal '', @response.body
    
    instance = 2424
    #######################################################################
    #                             CASE 02
    #  PUT /instances/:id with wrong id
    #######################################################################
    pre_count = DetailValue.count
    put :update, {:format => 'json', :id => instance, :instance => resource.to_json}, {'user' => user}
    post_count = DetailValue.count
    json = {:errors => ["Instance[#{instance}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body
    assert_equal 0, post_count - pre_count
    
    
    
  end
  
  def test_put_without_lock_version
    
    user = User.find @db1_admin_user_id
    
    instance = 200
    name = 1200
    description = 1202
    resource =  
      {
        #:lock_version => Instance.find(instance).lock_version.to_i, 
        :Name => [
                    {
                      :id => name, 
                      :lock_version => DetailValue.find(name).lock_version.to_i,
                      :value => "WAS COMPILER!"
                    }, 
                    {:value => "GREEN OLD BOOK"}
                  ], 
                  
        :Description => [
                            {
                              :id => 1202, 
                              :lock_version => DetailValue.find(description).lock_version.to_i,
                              :value => "What can we say on this????"
                              
                              }
                         ]
      }
      
    #######################################################################
    #                             CASE 01
    #  PUT /instances/:id with all ok
    #######################################################################
    pre_count = DetailValue.count
    put :update, {:format => 'json', :id => instance, :instance => resource.to_json}, {'user' => user}
    post_count = DetailValue.count
    json = {:errors => ['Provide lock_version for update/delete operations']}.to_json
    assert_response 400
    assert_equal json, @response.body
    assert_equal 0, post_count - pre_count
    JSON.parse(json)
    #assert_equal '', @response.body
  end
  
  def test_put_without_lock_version_for_value
    
    user = User.find @db1_admin_user_id
    
    instance = 200
    name = 1200
    description = 1202
    resource =  
      {
        :lock_version => Instance.find(instance).lock_version.to_i, 
        :Name => [
                    {
                      :id => name, 
                      :lock_version => DetailValue.find(name).lock_version.to_i,
                      :value => "WAS COMPILER!"
                    }, 
                    {:value => "GREEN OLD BOOK"}
                  ], 
                  
        :Description => [
                            {
                              :id => description, 
                              #:lock_version => DetailValue.find(description).lock_version.to_i,
                              :value => "What can we say on this????"
                              
                              }
                         ]
      }
      
    #######################################################################
    #                             CASE 01
    #  PUT /instances/:id with all ok
    #######################################################################
    pre_count = DetailValue.count
    put :update, {:format => 'json', :id => instance, :instance => resource.to_json}, {'user' => user}
    post_count = DetailValue.count
    json = "Provide lock_version for detail value #{description}"
    assert_response 400

    response_body = JSON.parse(@response.body)['message']

    assert_equal json, response_body
    assert_equal 0, post_count - pre_count
    
    #assert_equal '', @response.body
  end
  
  def test_put_with_wrong_values_ids
    user = User.find @db1_admin_user_id
    
    instance = 200
    name = 1200
    description = 1202
    pages = 4785
    resource =  
      {
        :lock_version => Instance.find(instance).lock_version.to_i,
        :Name => [
                    {
                      :id => name, 
                      :lock_version => DetailValue.find(name).lock_version.to_i,
                      :value => "WAS COMPILER!"
                    }, 
                    {:value => "GREEN OLD BOOK"}
                  ], 
                  
        :Description => [
                            {
                              :id => description, 
                              :lock_version =>DetailValue.find(description).lock_version.to_i,
                              :value => "What can we say on this????"
                              }
                         ],
        
        :Pages => [{:id => pages, :lock_version => 0, :value => 748}]
      }
      
    #######################################################################
    #                             CASE 01
    #  PUT /instances/:id with all ok
    #######################################################################
    pre_count = DetailValue.count
    put :update, {:format => 'json', :id => instance, :instance => resource.to_json}, {'user' => user}
    post_count = DetailValue.count
    json = "Detail 'Pages' does not have a value with ID 4785"

    response_body = JSON.parse(@response.body)['message']

    assert_equal json, response_body
    assert_response 400
    assert_equal 0, post_count - pre_count
    
  end
  
  def test_put_with_wrong_details
    user = User.find @db1_admin_user_id
    
    instance = 200
    name = 1200
    description = 1202
    
    resource =  
      {
        :lock_version => Instance.find(instance).lock_version.to_i,
        
        :Name => [
                    {
                      :id => 1200, 
                      :lock_version => DetailValue.find(name).lock_version.to_i,
                      :value => "WAS COMPILER!"}, 
                    {:value => "GREEN OLD BOOK"}
                  ], 
                  
        :Description => [
                            {
                              :id => 1202, 
                              :lock_version => DetailValue.find(description).lock_version.to_i,
                              :value => "What can we say on this????"}
                         ],
         :AgeField => [:value => 457]
      }
      
    #######################################################################
    #                             CASE 01
    #  PUT /instances/:id with all ok
    #######################################################################
    
    
    put :update, {:format => 'json', :id => instance, :instance => resource.to_json}, {'user' => user}
    #json = Instance.find(200).to_json(:format => 'json')
    assert_response 200
    #assert_equal json, @response.body    

  end
  
  def test_put_with_no_details
    
    user = User.find(@db1_admin_user_id)
    
    entity = 100
    instance = 200
    
    instances =   {
      :lock_version => Instance.find(instance).lock_version.to_i
#        "Name" =>               ["Dummy Book", "Instant Book", "Cook Book"],
#        "Description" =>        ["A Dummp book not yet published"],
#        "Published" =>          ["1919/12/12 00:00:00 +0500", "2018/02/06 00:00:00 +0500"],
#        "Pages" =>              [1284],
#        "Category" =>           [1003,1007],
#        "Email" =>              ["abc@email.com", "def@email.com"],
#        "Website" =>            ["http://www.ali.com", "http://www.raph.com"]
      }
      

    
    
    
    #######################################################################
    #                          CASE 01
    #  POST /entities/instances with all ok                         
    #######################################################################
    
    json = {:errors => ["Instance must mention at least one detail value to be created/updated"]}.to_json
    put :update, {:format => 'json', :entity_id => entity, :id => instance, :instance => instances.to_json},
      {'user' => user}
    
    assert_response 400
    assert_equal json, @response.body
    
  end
  
  def test_put_with_setting_value_nil
    user = User.find @db1_admin_user_id
    
    instance = 200
    name = 1200
    resource =  
      {
        :lock_version => Instance.find(instance).lock_version.to_i,
        :Name => [
                    {
                      :id => name,
                      :lock_version => DetailValue.find(name).lock_version.to_i,
                      :value => nil}
                    
                  ]
                  
      }
      
    #######################################################################
    #                             CASE 01
    #  PUT /instances/:id with all ok
    #######################################################################
    pre_count = DetailValue.count
    put :update, {:format => 'json', :id => instance, :instance => resource.to_json}, {'user' => user}
    post_count = DetailValue.count
    #json = Instance.find(instance).to_json(:format => 'json')
    assert_response :success
    #assert_equal json, @response.body
    assert_equal 1, pre_count - post_count
    #JSON.parse(json)
    #assert_equal '', @response.body
  end
  
  def test_get_and_put
    user = User.find_by_id @db1_admin_user_id
    
    id = 200
    res_name = 'instance'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    #assert_equal '', @response.body
    
    resource = JSON.parse(@response.body)
    
    
    #resource['Name'].push( [{:value => 'TEST NAME 1'}, {:value => 'TEST NAME 2'}])
    resource['Name'].push({:value => 'TEST NAME 1'})
    resource['Name'].push({:value => 'TEST NAME 2'})
     
    put :update, {:format => 'json', :id => id, res_name => resource.to_json}, {'user' => user}
    #assert_equal '', @response.body
    
    assert_response 200
    new_val = JSON.parse(@response.body)
    #assert_equal resource['Name'], new_val['Name']    
    
  end
  
  def test_get_and_put_conflict
    user = User.find_by_id @db1_admin_user_id
    
    id = 200
    res_id = 78
    res_name = 'instance'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource = JSON.parse(@response.body)
    
    resource['name'] = [{:value => 'VAL1'}, {:value => 'VAL2'}, ]
    resource['url'] = 'http://localhost:300/instances/' + res_id.to_s + '.json'
    
    json = {:errors => ["Requested ID is #{id} and ID in resource is #{res_id}. Are you dispatching your resource at the right location?"]}.to_json
    put :update, {:format => 'json', :id => id, res_name => resource.to_json}, {'user' => user}
    assert_response 400
    #assert_equal '', @response.body
    assert_equal json, @response.body
  end
  
  def test_get_and_put_version_conflict
    user = User.find_by_id @db1_admin_user_id
    
    id = 200
    res_name = 'instance'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource1 = JSON.parse(@response.body)
    
    resource1['Name'][0]['value'] = 'GET AND PUT TEST'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource2 = JSON.parse(@response.body)
    
    resource2['Name'][0]['value'] = 'GET AND PUT TEST8'
    
    put :update, {:format => 'json', :id => id, res_name => resource1.to_json}, {'user' => user}
    #assert_equal '', @response.body
    assert_response 200

    new_val = JSON.parse(@response.body)

    #assert_equal new_val, ''
    assert_equal resource1['Name'][0]['value'], new_val['Name'][0]['value']
    
    json = "Attempted to update a stale object"
    put :update, {:format => 'json', :id => id, res_name => resource2.to_json}, {'user' => user}
    assert_response 409

    response_body = JSON.parse(@response.body)['message']

    assert_equal json, response_body
    
    
    
    
  end
  
  def test_get_and_put_detail_is_modified_from_elsewhere
    user = User.find_by_id @db1_admin_user_id
    
    # Get an instance
    id = 200
    get :show, {:format => 'json', :id => id}, {'user' => user}
    assert_response :success
    instance = JSON.parse(@response.body)
    
    # Get a detail value, modify and save
    value_id = 1200
    value = DetailValue.find(value_id)
    value.value = 'TEST CONFLICT TEST'
    value.save!
    
    #modify the instance
    instance['Name'][0]['value'] = 'TEST TEST TEST'
    
    json = 'Attempted to update a stale object'
    put :update, {:format => 'json', :id => id, :instance => instance.to_json}, {'user' => user}
    assert_response 409

    response_body = JSON.parse(@response.body)['message']

    assert_equal json, response_body
    
    # Check version statys the same for instance
    assert_equal instance['lock_version'].to_i, Instance.find(id).lock_version.to_i
    
    
    
    
    
    
  end
  
  def test_delete
    # CASE 01: DELETE /entities/instances/:id with all ok
    # CASE 02: DELETE /entities/instances/:id with instance does not exists
    # CASE 03: DELETE /entities/instances/:id with entity does not exists
    # CASE 04: DELETE /entities/instances/:id with both unrelated
    # CASE 05: DELETE /instances/:id with all ok
    # CASE 06: DELETE /instances/:id with wrong id
    
    
    user = User.find @db1_admin_user_id
    
    entity = 100
    instance = 200
    lock_version = Instance.find(instance).lock_version.to_i
    #####################################################################
    #                            CASE 01
    #  DELETE /entities/instances/:id with all ok                          
    #####################################################################
    pre_instance_count = Instance.count
    pre_detailvalue_count = DetailValue.count
    pre_integervalue_count = IntegerDetailValue.count
    pre_datevalue_count = DateDetailValue.count
    pre_ddlvalue_count = DdlDetailValue.count
    
    
    delete :destroy, {:format => 'json', :lock_version => lock_version, :entity_id => entity, :id => instance}, {'user' => user}
    #assert_equal '', @response.body
    assert_response :success
    post_instance_count = Instance.count
    post_detailvalue_count = DetailValue.count
    post_integervalue_count = IntegerDetailValue.count
    post_datevalue_count = DateDetailValue.count
    post_ddlvalue_count = DdlDetailValue.count
    
    assert_equal 1, pre_instance_count - post_instance_count
    assert_equal 8, pre_detailvalue_count - post_detailvalue_count
    assert_equal 1, pre_integervalue_count - post_integervalue_count
    assert_equal 2, pre_datevalue_count - post_datevalue_count
    assert_equal 2, pre_ddlvalue_count - post_ddlvalue_count
    
    
    
    
    
    entity = 100
    instance = 9879 #200
    lock_version = 7887
    #####################################################################
    #                            CASE 02
    #  DELETE /entities/instances/:id with wrong instance
    #####################################################################
    json = {:errors => ["Instance[#{instance}] does not exists"]}.to_json
    delete :destroy, {:format => 'json', :lock_version => lock_version, :entity_id => entity, :id => instance}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    JSON.parse(json)
    
    entity = 7979741 #100
    instance = 200
    lock_version = 797
    #####################################################################
    #                            CASE 03
    #  DELETE /entities/instances/:id with wrong entity
    #####################################################################
    json = {:errors => ["Entity[#{entity}] does not exists"]}.to_json
    delete :destroy, {:format => 'json', :lock_version => lock_version, :entity_id => entity, :id => instance}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    JSON.parse(json)
    
    entity = 100
    instance = 70 #200
    lock_version = 7979
    #####################################################################
    #                            CASE 04
    #  DELETE /entities/instances/:id with both irrelevant
    #####################################################################
    json = {:errors => ["Instance[#{instance}] does not belong to Entity[#{entity}]"]}.to_json
    delete :destroy, {:format => 'json', :lock_version => lock_version, :entity_id => entity, :id => instance}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    JSON.parse(json)
    
    entity = 100
    instance = 201
    lock_version = Instance.find(instance).lock_version.to_i
    #####################################################################
    #                            CASE 05
    #  DELETE /instances/:id with all ok                          
    #####################################################################
    pre_instance_count = Instance.count
    pre_detailvalue_count = DetailValue.count
    pre_integervalue_count = IntegerDetailValue.count
    pre_datevalue_count = DateDetailValue.count
    pre_ddlvalue_count = DdlDetailValue.count
    
    
    delete :destroy, {:format => 'json', :lock_version => lock_version, :entity_id => entity, :id => instance}, {'user' => user}
    assert_response :success
    post_instance_count = Instance.count
    post_detailvalue_count = DetailValue.count
    post_integervalue_count = IntegerDetailValue.count
    post_datevalue_count = DateDetailValue.count
    post_ddlvalue_count = DdlDetailValue.count
    
    assert_equal 1, pre_instance_count - post_instance_count
    assert_equal 6, pre_detailvalue_count - post_detailvalue_count
    assert_equal 1, pre_integervalue_count - post_integervalue_count
    assert_equal 2, pre_datevalue_count - post_datevalue_count
    assert_equal 3, pre_ddlvalue_count - post_ddlvalue_count
    
    


    
    entity = 100
    instance = 9879 #200
    lock_version = 797
    #####################################################################
    #                            CASE 05
    #  DELETE /instances/:id with wrong instance
    #####################################################################
    json = {:errors => ["Instance[#{instance}] does not exists"]}.to_json
    delete :destroy, {:format => 'json', :lock_version => lock_version, :id => instance}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    JSON.parse(json)
    
  end
  
  def test_delete_with_version_conflict
    # Get a resource
    # Get its lock version
    # modify resource
    # post it back
    user = User.find_by_id @db1_admin_user_id
    
    id = 200
    res_name = 'instance'
    lock_version = nil
    klass = Instance
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource = JSON.parse(@response.body)
    
    lock_version = resource['lock_version']
    
    # PUT it back
    put :update, {:format => 'json', res_name => resource.to_json, :id => id}, {'user' => user}
    
    json = 'Attempted to delete a stale object'
    pre_count = klass.count
    delete :destroy, {:format => 'json', :id => id, :lock_version => lock_version}, {'user' => user}
    post_count = klass.count
    assert_response 409

    response_body = JSON.parse(@response.body)['message']

    assert_equal 0, post_count - pre_count
    assert_equal json, response_body
  end
  
  def test_delete_without_lock_version
     user = User.find @db1_admin_user_id
     
    instance = 200
    
    json = {:errors => ['Provide lock_version for update/delete operations']}.to_json
    delete :destroy, {:format => 'json', :id => instance}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    
  end
  
  
  
end
