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
require 'rest/values_controller'


# assert_response status_code
# assert_redirect
# assert_redirect_to
# Re-raise errors caught by the controller.
class Rest::ValuesController; def rescue_action(e) raise e end; end


#FIXME: Design a new entity, its details of all data types
# and the detail values for them and then write tests. (DONE)
# Entity ID is 100
#FIXME: Add the tests which check the relaition ships among the parameters

class ValuesControllerTest < Test::Unit::TestCase
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
    @controller   = Rest::ValuesController.new
    @request      = ActionController::TestRequest.new
    @response      = ActionController::TestResponse.new
    
    @db1_admin_user_id = 2
  end
  
  
  def test_without_login
    # Will be reimplemented after REST Auth
    assert true
    
#    id = 1
#    get :show, {:format => 'json', :id => id}, {'user' => nil}
#    assert_response 401
#    json = %Q~{"errors": ["Please login to consume the REST API"]}~
#    assert_equal json, @response.body  
  end 
  
  def test_accessing_irrelevant_item
    # CASE 01: Getting a value which does not belong to user
    instance = 25
    detail = 23
    value = 232
    user = User.find @db1_admin_user_id
    res_id = detail
    res_name = 'Detail'
    json = {:errors =>["#{res_name}[#{res_id}] does not belong to User[#{user.id}] (\"#{user.login}\")"]}.to_json
    get :show, {:format => 'json', :instance_id => instance, 
      :detail_id => detail, 
      :id => value
      },
        {'user' => user}
    assert_equal json, @response.body
  end
  
  def test_get_all
    # CASE 01: GET /instances/:instance_id/details/:detail_id/values with all ok
    # CASE 02: GET /instances/:instance_id/details/:detail_id/values with wrong detail
    # CASE 03: GET /instances/:instance_id/details/:detail_id/values with wrong instance
    # CASE 04 GET /instances/:instance_id/details/:detail_id/values detail not belongs to entity
    
    
    user = User.find @db1_admin_user_id
    
    
    instance = 90
    detail = 48
    ######################################################################
    #                            CASE 01
    #   GET /details/:detail_id/detail_values with all ok
    ######################################################################
    json = get_all_values(instance, detail)
    get :index, {:format => 'json', :instance_id => instance, :detail_id => detail}, {'user' => user}
    assert_response :success
    result = JSON.parse(@response.body)
    assert_equal json.length, result['resources'].length
    
    
    instance = 90
    detail = 987 #48
    ######################################################################
    #                            CASE 02
    #   GET /details/:detail_id/detail_values wtih wrong detail
    ######################################################################
    json = {:errors => [ "Detail[#{detail}] does not exists"]}.to_json
    get :index, {:format => 'json', :instance_id => instance, :detail_id => detail}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    
    instance = 9877 #90
    detail = 48
    ######################################################################
    #                            CASE 03
    #   GET /details/:detail_id/detail_values wtih wrong instance
    ######################################################################
    json = {:errors => [ "Instance[#{instance}] does not exists"]}.to_json
    get :index, {:format => 'json', :instance_id => instance, :detail_id => detail}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    
    instance = 90 #200
    detail = 74
    value = 1200
    ################################################################
    #                           CASE 05
    #  GET /instances/:instance_id/details/:detail_id/values where detail and instance do not belong to each other
    ################################################################
    json = {:errors => ["Detail[#{detail}] does not belong to Instance[#{instance}]"]}.to_json
    post :index, { :format => 'json', 
                    :instance_id => instance, 
                    :detail_id => detail
                  }, {'user' => user}
    
    assert_response 400
    assert_equal json, @response.body
    
    
    
  end
  
  def test_get_all_with_pagination
    # CASE 01: Mention of start_index and max_results
    # CASE 02: Mention of Order by with direction
    # CASE 03: Mention of Order by without direction
    # CASE 04: Mention a condition also
    
    user = User.find_by_id(@db1_admin_user_id)
    
    instance = 200
    detail = 79
    start_index = 0
    max_results = 3
    order_by = 'name'
    direction = 'DESC'
    table_name = 'data_types'
    conditions = 'database_id=6'
    #total_records = Detail.count_by_sql "SELECT COUNT(*) FROM  #{table_name} WHERE #{conditions}"
    conditions = 'id=50'
    
    total_records = DetailValue.count :conditions => "instance_id=#{instance} AND detail_id=#{detail}"
    max_results = 2
    #########################################################
    #                        CASE 01
    #        Mention of start_index and max_results
    #########################################################
    get :index, {
      :instance_id => instance,
      :detail_id => detail,
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
    
    
    
    order_by = 'value'
    direction = 'desc'
    #########################################################
    #                        CASE 02
    #        Mention of order by with direction
    #########################################################
    get :index, {
      :instance_id => instance,
      :detail_id => detail,
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
    assert_equal 1204, result['resources'][0]['url'].chomp('.json')[/\d+$/].to_i
    
    #########################################################
    #                        CASE 03
    #        Mention of order by without direction
    #########################################################
    get :index, {
      :instance_id => instance,
      :detail_id => detail,
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
    assert_equal 1211, result['resources'][0]['url'].chomp('.json')[/\d+$/].to_i
    
    conditions = "value='dr_pressman@aol.com'"
    #########################################################
    #                        CASE 04
    #        Mention of order by specifying condition
    #########################################################
    get :index, {
      :instance_id => instance,
      :detail_id => detail,
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
    assert_equal 1211, result['resources'][0]['url'].chomp('.json')[/\d+$/].to_i
  end
  
  def test_get_single
    # CASE 01: GET /instances/:instance_id/details/:detail_id/values/:id with all ok
    # CASE 02: GET /instances/:instance_id/details/:detail_id/values/:id with wrong value id
    # CASE 03: GET /instances/:instance_id/details/:detail_id/values/:id with wrong detail id
    # CASE 04: GET /instances/:instance_id/details/:detail_id/values/:id with wrong instance id
    # CASE 05 GET /instances/:instance_id/details/:detail_id/values/:id do not belong to each other
    
    
    user = User.find @db1_admin_user_id
    
    instance = 90
    detail = 48
    value = 437
    ############################################################################
    #                              CASE 01
    #  GET /instances/:instance_id/details/:detail_id/values/:id with all ok
    ############################################################################
    json = get_single_value(detail, value)
    get :show, {:format => 'json', :instance_id => instance, :detail_id => detail, :id => value}, {'user' => user}
    assert_response :success
    assert_similar json, @response.body

    
    instance = 90
    detail = 48
    value = 18974 #437
    ############################################################################
    #                              CASE 02
    #  GET /instances/:instance_id/details/:detail_id/values/:id with wrong value id
    ############################################################################
    json = {:errors => [ "#{Detail.find(detail).data_type.class_name}[#{value}] does not exists"]}.to_json
    get :show, {:format => 'json', :instance_id => instance, :detail_id => detail, :id => value}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    
    instance = 90
    detail = 754 #48
    value = 437
    ############################################################################
    #                              CASE 03
    #  GET /instances/:instance_id/details/:detail_id/values/:id with wrong value id
    ############################################################################
    json = {:errors => [ "Detail[#{detail}] does not exists"]}.to_json
    get :show, {:format => 'json', :instance_id => instance, :detail_id => detail, :id => value}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    
    instance = 789 #90 
    detail = 48
    value = 437
    ############################################################################
    #                              CASE 04
    #  GET /instances/:instance_id/details/:detail_id/values/:id with wrong value id
    ############################################################################
    json = {:errors => [ "Instance[#{instance}] does not exists"]}.to_json
    get :show, {:format => 'json', :instance_id => instance, :detail_id => detail, :id => value}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    
    instance =200
    detail = 74
    value = 1208 #1200
    ################################################################
    #                           CASE 05
    #  GET /instances/:instance_id/details/:detail_id/values/:id value is not of detail
    ################################################################
    json = {:errors => ["Value[#{value}] does not belong to Detail[#{detail}] and Instance[#{instance}]"]}.to_json
    post :get, { :format => 'json', 
                    :instance_id => instance, 
                    :detail_id => detail,
                    :id => value
                  }, {'user' => user}
    
    assert_response 400
    assert_equal json, @response.body
    
    
  end
  
  def test_post
    # CASE 01: POST /instances/:instance_id/details/:detail_id/values with all ok
    # CASE 02: POST /instances/:instance_id/details/:detail_id/values with missing values params
    # CASE 03: POST /instances/:instance_id/details/:detail_id/values with wrong detail id
    # CASE 04: POST /instances/:instance_id/details/:detail_id/values with wrong instance id
    # CASE 05: POST /instances/:instance_id/details/:detail_id/values with detail not related to instance
    
    user = User.find @db1_admin_user_id
    
    instance = 200
    detail = 74
    value = 1200
    values = {:value => ["Raphael",  "Mohsin", "Hijazee"]}
    
    ################################################################
    #                           CASE 01
    #  POST /instances/:instance_id/details/:detail_id/values with all ok
    ################################################################
    pre_count = DetailValue.count
    post :create, { :format => 'json', 
                    :instance_id => instance, 
                    :detail_id => detail, 
                    :id => value, 
                    :value => values.to_json
                  }, {'user' => user}
    post_count = DetailValue.count
    #assert_equal '', @response.body
    assert_response 201
    assert_equal 3, post_count - pre_count
    
    json = JSON.parse(@response.body)
    assert_equal Array, json.class
    assert_equal 3, json.length
    #assert_equal '', @response.body
    

    
    instance = 90
    detail = 48
    value = 437
    values = {:value => ["Raphael", "Rapph", 'raphinou', "Mohsin", "Hijazee"]}
    
    ################################################################
    #                           CASE 02
    #  POST /instances/:instance_id/details/:detail_id/values with missgin values
    ################################################################
    json = {:errors =>  [ 'Provide the JSON of the values to be created/updated in values parameter']}.to_json
    pre_count = DetailValue.count
    post :create, { :format => 'json', 
                    :instance_id => instance, 
                    :detail_id => detail, 
                    :id => value
                  }, {'user' => user}
    post_count = DetailValue.count
    assert_response 400
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    
    
    instance = 90
    detail = 987 #48
    value = 437
    values = {:value => ["Raphael", "Rapph", 'raphinou', "Mohsin", "Hijazee"]}
    
    ################################################################
    #                           CASE 03
    #  POST /instances/:instance_id/details/:detail_id/values wrong detail
    ################################################################
    json = {:errors => [ "Detail[#{detail}] does not exists"]}.to_json
    pre_count = DetailValue.count
    post :create, { :format => 'json', 
                    :instance_id => instance, 
                    :detail_id => detail, 
                    :value =>  values.to_json,
                    :id => value
                  }, {'user' => user}
    post_count = DetailValue.count
    assert_response 404
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    
    instance = 987 #90
    detail = 48
    value = 437
    values = {:value => ["Raphael", "Rapph", 'raphinou', "Mohsin", "Hijazee"]}
    ################################################################
    #                           CASE 04
    #  POST /instances/:instance_id/details/:detail_id/values wrong instance
    ################################################################
    json = {:errors => [ "Instance[#{instance}] does not exists"]}.to_json
    pre_count = DetailValue.count
    post :create, { :format => 'json', 
                    :instance_id => instance, 
                    :detail_id => detail, 
                    :value =>  values.to_json,
                    :id => value
                  }, {'user' => user}
    post_count = DetailValue.count
    assert_response 404
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    
    
    instance = 90 #200
    detail = 74
    value = 1200
    values = {:value => ["Raphael",  "Mohsin", "Hijazee"]}
    ################################################################
    #                           CASE 05
    #  POST /instances/:instance_id/details/:detail_id/values with all ok
    ################################################################
    json = {:errors => ["Value[#{value}] does not belong to Detail[#{detail}] and Instance[#{instance}]"]}.to_json
    pre_count = DetailValue.count
    post :create, { :format => 'json', 
                    :instance_id => instance, 
                    :detail_id => detail, 
                    :id => value, 
                    :value => values.to_json
                  }, {'user' => user}
    post_count = DetailValue.count
    assert_response 400
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    
    
    
  end
  
  def test_post_with_max_limit
    user = User.find @db1_admin_user_id
    
    instance = 200
    detail = 74
    value = 1200
    values = {:value => ["Raphael", "Rapph", 'raphinou', "Mohsin", "Hijazee"]}
    ################################################################
    #                           CASE 02
    #  POST /instances/:instance_id/details/:detail_id/values with max limits
    ################################################################
    msg = 'Validation failed: Name Name[74] of Books[100] cannot have more then 6 values'
    pre_count = DetailValue.count
    post :create, { :format => 'json', 
                    :instance_id => instance, 
                    :detail_id => detail, 
                    :value => values.to_json,
                    :id => value
                  }, {'user' => user}
    post_count = DetailValue.count
    assert_response 400
    assert_equal 0, post_count - pre_count
    assert_equal msg, JSON.parse(@response.body)['message']
    
  end
  
  def test_post_and_put_all_value_types
    user = User.find @db1_admin_user_id
    entity = 100
    
    # Create an Instance
    instance = Instance.new
    instance.entity_id = entity
    instance.save
    
#    74	Name            madb_short_text
#    75	Description     madb_long_text
#    76	Published       madb_date
#    77	Pages           madb_integer
#    78	Category        madb_choose_in_list
#    79	Email           madb_email
#    80	Website         madb_web_url
#    82	Picture         madb_file_attachment

    # The detail ids
    name          = 74
    description   = 75
    published     = 76
    pages         = 77
    category      = 78
    email         = 79
    website       = 80
    picture       = 82
    
    value = {:value => ['val1', 'val2']}
    ############################################################
    # POST and PUT  madb_short_text
    ############################################################
    pre_count = DetailValue.count
    post :create, 
      {
        :instance_id => instance.id,
        :detail_id => name,
        :value => value.to_json,
        :format => 'json'
      },
      {'user' => user}
      
    post_count = DetailValue.count
    assert_response 201
    assert_equal 2, post_count - pre_count
    #assert_equal '', @response.body
    
    value_id = JSON.parse(@response.body)[0].chomp('.json')[/\d+$/].to_i
    
    
    # NOTE THAT ONLY FIRST WILL BE CONSIDERD!!! JUST TO DEMONSTRATE THIS BEHAVIOUR!
    # ITS NOT A GOOD USE OF THE API!!!
    # INSTEAD DO THIS:
    # value = {:value => 'mohsin'}
    # Providing the lock_version by hand. Not a good approach for tests
    # but because we created this value in tests, its no harm
    value = {:value => ['mohsin', 'asdf', 'dedomenon'], :lock_version => 0}
    #################### NOW DO A PUT ####################
    pre_count = DetailValue.count
    put :update, 
      {
        :instance_id => instance.id,
        :detail_id => name,
        :value => value.to_json,
        :id => value_id,
        :format => 'json'
      },
      {'user' => user}
      
    #assert_equal '', @response.body
    post_count = DetailValue.count
    assert_response 200
    assert_equal 0, post_count - pre_count
    assert_equal DetailValue.find(value_id).value, value[:value][0]
    
    value = {:value => ['val1']}
    ############################################################
    # POST and PUT  madb_long_text
    ############################################################
    pre_count = DetailValue.count
    post :create, 
      {
        :instance_id => instance.id,
        :detail_id => description,
        :value => value.to_json,
        :format => 'json'
      },
      {'user' => user}

#    assert_equal '', @response.body
    post_count = DetailValue.count
    assert_response 201
    assert_equal 1, post_count - pre_count
    value_id = JSON.parse(@response.body)[0].chomp('.json')[/\d+$/].to_i
    
    # NOTE THAT ONLY FIRST WILL BE CONSIDERD!!! JUST TO DEMONSTRATE THIS BEHAVIOUR!
    # ITS NOT A GOOD USE OF THE API!!!
    # INSTEAD DO THIS:
    # value = {:value => 'mohsin'}
    # Providing the lock_version by hand. Not a good approach for tests
    # but because we created this value in tests, its no harm
    value = {:value => ['mohsin', 'asdf', 'dedomenon'], :lock_version => 0}
    #################### NOW DO A PUT ####################
    pre_count = DetailValue.count
    put :update, 
      {
        :instance_id => instance.id,
        :detail_id => description,
        :value => value.to_json,
        :id => value_id,
        :format => 'json'
      },
      {'user' => user}
      
    #assert_equal '', @response.body
    post_count = DetailValue.count
    assert_response 200
    assert_equal 0, post_count - pre_count
    assert_equal DetailValue.find(value_id).value, value[:value][0]
    

    value = {:value => ["1919/12/12 00:00:00 +0500", "2018/02/06 00:00:00 +0500"]}
    ############################################################
    # POST and PUT  madb_date
    ############################################################
    pre_count = DateDetailValue.count
    post :create, 
      {
        :instance_id => instance.id,
        :detail_id => published,
        :value => value.to_json,
        :format => 'json'
      },
      {'user' => user}
      
    #assert_equal '', @response.body
    post_count = DateDetailValue.count
    assert_response 201
    assert_equal 2, post_count - pre_count
    value_id = JSON.parse(@response.body)[0].chomp('.json')[/\d+$/].to_i
    
    # NOTE THAT ONLY FIRST WILL BE CONSIDERD!!! JUST TO DEMONSTRATE THIS BEHAVIOUR!
    # ITS NOT A GOOD USE OF THE API!!!
    # INSTEAD DO THIS:
    # value = {:value => 'mohsin'}
    # Providing the lock_version by hand. Not a good approach for tests
    # but because we created this value in tests, its no harm
    value = {:value => ["2018/02/06 00:00:00 +0500", "1919/12/12 00:00:00 +0500"], :lock_version => 0}
    #################### NOW DO A PUT ####################
    pre_count = DateDetailValue.count
    put :update, 
      {
        :instance_id => instance.id,
        :detail_id => published,
        :value => value.to_json,
        :id => value_id,
        :format => 'json'
      },
      {'user' => user}
    
    #assert_equal '', @response.body
    post_count = DateDetailValue.count
    assert_response 200
    assert_equal 0, post_count - pre_count
    assert_equal DateDetailValue.find(value_id).value.to_date, value[:value][0].to_date
    
    
    value = {:value => [758]}
    ############################################################
    # POST and PUT  madb_integer
    ############################################################
    pre_count = IntegerDetailValue.count
    post :create, 
      {
        :instance_id => instance.id,
        :detail_id => pages,
        :value => value.to_json,
        :format => 'json'
      },
      {'user' => user}
      
    post_count = IntegerDetailValue.count
    assert_response 201
    assert_equal 1, post_count - pre_count
    value_id = JSON.parse(@response.body)[0].chomp('.json')[/\d+$/].to_i
    
    # NOTE THAT ONLY FIRST WILL BE CONSIDERD!!! JUST TO DEMONSTRATE THIS BEHAVIOUR!
    # ITS NOT A GOOD USE OF THE API!!!
    # INSTEAD DO THIS:
    # value = {:value => 'mohsin'}
    # Providing the lock_version by hand. Not a good approach for tests
    # but because we created this value in tests, its no harm
    value = {:value => 147, :lock_version => 0}
    #################### NOW DO A PUT ####################
    pre_count = IntegerDetailValue.count
    put :update, 
      {
        :instance_id => instance.id,
        :detail_id => pages,
        :value => value.to_json,
        :id => value_id,
        :format => 'json'
      },
      {'user' => user}
      
    #assert_equal '', @response.body
    post_count = IntegerDetailValue.count
    assert_response 200
    assert_equal 0, post_count - pre_count
    assert_equal IntegerDetailValue.find(value_id).value, value[:value]
    
    value = {:value => ['Science', 'Fiction']}
    ############################################################
    # POST and PUT  madb_choose_in_list
    ############################################################
    pre_count = DdlDetailValue.count
    post :create, 
      {
        :instance_id => instance.id,
        :detail_id => category,
        :value => value.to_json,
        :format => 'json'
      },
      {'user' => user}
      
    post_count = DdlDetailValue.count
    assert_response 201
    assert_equal 2, post_count - pre_count
    value_id = JSON.parse(@response.body)[0].chomp('.json')[/\d+$/].to_i
    
    # NOTE THAT ONLY FIRST WILL BE CONSIDERD!!! JUST TO DEMONSTRATE THIS BEHAVIOUR!
    # ITS NOT A GOOD USE OF THE API!!!
    # INSTEAD DO THIS:
    # value = {:value => 'mohsin'}
    # Providing the lock_version by hand. Not a good approach for tests
    # but because we created this value in tests, its no harm
    value = {:value => ['Fiction'], :lock_version => 0}
    #################### NOW DO A PUT ####################
    pre_count = DdlDetailValue.count
    put :update, 
      {
        :instance_id => instance.id,
        :detail_id => category,
        :value => value.to_json,
        :id => value_id,
        :format => 'json'
      },
      {'user' => user}
      
    #assert_equal '', @response.body
    post_count = DdlDetailValue.count
    assert_response 200
    assert_equal 0, post_count - pre_count
    assert_equal DdlDetailValue.find(value_id).value, value[:value][0]
    
        value = {:value => ['m_hijazee@yahoo.com', 'm_hijazee@hotmail.com']}
    ############################################################
    # POST and PUT  madb_email
    ############################################################
    pre_count = DetailValue.count
    post :create, 
      {
        :instance_id => instance.id,
        :detail_id => email,
        :value => value.to_json,
        :format => 'json'
      },
      {'user' => user}
      
    post_count = DetailValue.count
    assert_response 201
    assert_equal 2, post_count - pre_count
    value_id = JSON.parse(@response.body)[0].chomp('.json')[/\d+$/].to_i
    
    # NOTE THAT ONLY FIRST WILL BE CONSIDERD!!! JUST TO DEMONSTRATE THIS BEHAVIOUR!
    # ITS NOT A GOOD USE OF THE API!!!
    # INSTEAD DO THIS:
    # value = {:value => 'mohsin'}
    # Providing the lock_version by hand. Not a good approach for tests
    # but because we created this value in tests, its no harm
    value = {:value => ['mohsin@yahoo.com', 'asdf@asdf.com', 'dedomenon@info.net'], :lock_version => 0}
    #################### NOW DO A PUT ####################
    pre_count = DetailValue.count
    put :update, 
      {
        :instance_id => instance.id,
        :detail_id => email,
        :value => value.to_json,
        :id => value_id,
        :format => 'json'
      },
      {'user' => user}
      
    #assert_equal '', @response.body
    post_count = DetailValue.count
    assert_response 200
    assert_equal 0, post_count - pre_count
    assert_equal DetailValue.find(value_id).value, value[:value][0]
    
        value = {:value => ['val1', 'val2']}
    ############################################################
    # POST and PUT  madb_web_url
    ############################################################
    pre_count = DetailValue.count
    post :create, 
      {
        :instance_id => instance.id,
        :detail_id => website,
        :value => value.to_json,
        :format => 'json'
      },
      {'user' => user}
      
    post_count = DetailValue.count
    assert_response 201
    assert_equal 2, post_count - pre_count
    value_id = JSON.parse(@response.body)[0].chomp('.json')[/\d+$/].to_i
    
    # NOTE THAT ONLY FIRST WILL BE CONSIDERD!!! JUST TO DEMONSTRATE THIS BEHAVIOUR!
    # ITS NOT A GOOD USE OF THE API!!!
    # INSTEAD DO THIS:
    # value = {:value => 'mohsin'}
    # Providing the lock_version by hand. Not a good approach for tests
    # but because we created this value in tests, its no harm
    value = {:value => ['mohsin', 'asdf', 'dedomenon'], :lock_version => 0}
    #################### NOW DO A PUT ####################
    pre_count = DetailValue.count
    put :update, 
      {
        :instance_id => instance.id,
        :detail_id => website,
        :value => value.to_json,
        :id => value_id,
        :format => 'json'
      },
      {'user' => user}
      
    #assert_equal '', @response.body
    post_count = DetailValue.count
    assert_response 200
    assert_equal 0, post_count - pre_count
    assert_equal DetailValue.find(value_id).value, value[:value][0]
    
        value = {:value => ['pic1', 'pic2']}
    ############################################################
    # POST and PUT  madb_file_attachment
    ############################################################
    pre_count = DetailValue.count
    post :create, 
      {
        :instance_id => instance.id,
        :detail_id => picture,
        :value => value.to_json,
        :pic1 => fixture_file_upload('/files/logo-Ubuntu.png', 'image/png', :binary),
        :pic2 => fixture_file_upload('/files/logo-Ubuntu.png', 'image/png', :binary),
        :format => 'json'
      },
      {'user' => user}
      
    post_count = DetailValue.count
    #assert_equal '', @response.body
    assert_response 201
    assert_equal 2, post_count - pre_count
    value_id = JSON.parse(@response.body)[0].chomp('.json')[/\d+$/].to_i
    
    # NOTE THAT ONLY FIRST WILL BE CONSIDERD!!! JUST TO DEMONSTRATE THIS BEHAVIOUR!
    # ITS NOT A GOOD USE OF THE API!!!
    # INSTEAD DO THIS:
    # value = {:value => 'mohsin'}
    # Providing the lock_version by hand. Not a good approach for tests
    # but because we created this value in tests, its no harm
    value = {:value => ['newPic', 'asdf', 'dedomenon'], :lock_version => 1}
    #################### NOW DO A PUT ####################
    pre_count = DetailValue.count
    put :update, 
      {
        :instance_id => instance.id,
        :detail_id => picture,
        :value => value.to_json,
        :id => value_id,
        :newPic => fixture_file_upload('/files/logo-Ubuntu.png', 'image/png', :binary),
        :format => 'json'
      },
      {'user' => user}
      
    #assert_equal '', @response.body
    post_count = DetailValue.count
    assert_response 200
    assert_equal 0, post_count - pre_count
    #assert_equal DetailValue.find(value_id).value, value[:value][0]
    
    #instance.destroy
  end
  
  def test_put
    # CASE 01: PUT /instancs/:instance_id/details/:detail_id/values/:id with all ok
    # CASE 02: PUT /instancs/:instance_id/details/:detail_id/values/:id with missing value param
    # CASE 03: PUT /instancs/:instance_id/details/:detail_id/values/:id with wrong value id
    # CASE 04: PUT /instancs/:instance_id/details/:detail_id/values/:id with wrong detail id
    # CASE 05: PUT /instancs/:instance_id/details/:detail_id/values/:id with wrong instance id
    # CASE 06: PUT /instancs/:instance_id/details/:detail_id/values/:id with value and detail irrelevant
    
    
    user = User.find(@db1_admin_user_id)
    
    instance = 90
    detail = 48
    value = 437
    lock_version = DetailValue.find(value).lock_version.to_i
    new_value = {:lock_version => lock_version, :value =>'MOHSIN HIJAZEE'}
    ######################################################################
    #                              CASE 01
    #  PUT /instancs/:instance_id/details/:detail_id/values/:id with all ok
    ######################################################################
    put :update, {:format => 'json', 
                  :instance_id => instance, 
                  :detail_id => detail,
                  :id => value,
                  :value => new_value.to_json
                  },
                  {'user' => user}
                
    assert_response:success
    assert_equal DetailValue.find(value).value, new_value[:value]
    val = DetailValue.find(value).value
    assert_equal val, JSON.parse(@response.body)['value']
    
    
    instance = 90
    detail = 48
    value = 437
    lock_version = DetailValue.find(value).lock_version.to_i
    new_value = {:lock_version => lock_version, :value =>'MOHSIN HIJAZEE'}
    ######################################################################
    #                              CASE 02
    #  PUT /instancs/:instance_id/details/:detail_id/values/:id with missing value
    ######################################################################
    msg = 'Provide the value to be updated in value parameter'
    put :update, {:format => 'json', 
                  :instance_id => instance, 
                  :detail_id => detail,
                  :id => value
                  #value => new_value
                  },
                  {'user' => user}
                
    assert_response 400
    assert_equal msg, JSON.parse(@response.body)['errors'][0]
    
    
    instance = 90
    detail = 48
    value = 9887 #437
    lock_version = 97987
    new_value = {:lock_version => lock_version, :value =>'MOHSIN HIJAZEE'}
    ######################################################################
    #                              CASE 03
    #  PUT /instancs/:instance_id/details/:detail_id/values/:id with wrong value id
    ######################################################################
    msg = "#{Detail.find(detail).data_type.class_name}[#{value}] does not exists"
    put :update, {:format => 'json', 
                  :instance_id => instance, 
                  :detail_id => detail,
                  :id => value,
                  :value => new_value.to_json
                  },
                  {'user' => user}
                
    assert_response 404
    assert_equal msg, JSON.parse(@response.body)['errors'][0]
    
    instance = 90
    detail = 987 #48
    value = 437
    lock_version = DetailValue.find(value).lock_version.to_i
    new_value = {:lock_version => lock_version, :value =>'MOHSIN HIJAZEE'}
    ######################################################################
    #                              CASE 04
    #  PUT /instancs/:instance_id/details/:detail_id/values/:id with wrong detail id
    ######################################################################
    json = {:errors =>  [ "Detail[#{detail}] does not exists"]}.to_json
    put :update, {:format => 'json', 
                  :instance_id => instance, 
                  :detail_id => detail,
                  :id => value,
                  :value => new_value.to_json
                  },
                  {'user' => user}
                
    assert_response 404
    assert_equal json, @response.body
    
    
    instance = 9798 #90
    detail = 48
    value = 437
    lock_version = DetailValue.find(value).lock_version.to_i
    new_value = {:lock_version => lock_version, :value =>'MOHSIN HIJAZEE'}
    ######################################################################
    #                              CASE 05
    #  PUT /instancs/:instance_id/details/:detail_id/values/:id with wrong instance
    ######################################################################
    json = {:errors =>  [ "Instance[#{instance}] does not exists"]}.to_json
    put :update, {:format => 'json', 
                  :instance_id => instance, 
                  :detail_id => detail,
                  :id => value,
                  :value => new_value.to_json
                  },
                  {'user' => user}
                
    assert_response 404
    assert_equal json, @response.body
    
    
    instance = 200
    detail = 74
    value = 1208
    lock_version = DetailValue.find(value).lock_version.to_i
    new_value = {:lock_version => lock_version, :value =>'MOHSIN HIJAZEE'}
    ######################################################################
    #                              CASE 06
    #  PUT /instancs/:instance_id/details/:detail_id/values/:id all irrelevant
    ######################################################################
    json = {:errors =>  ["Value[#{value}] does not belong to Detail[#{detail}] and Instance[#{instance}]"]}.to_json
    put :update, {:format => 'json', 
                  :instance_id => instance, 
                  :detail_id => detail,
                  :id => value,
                  :value => new_value.to_json
                  },
                  {'user' => user}
                
    assert_response 400
    assert_equal json, @response.body
    
    
    
    
  end
  
  def test_put_without_lock_version
        user = User.find(@db1_admin_user_id)
    
    instance = 90
    detail = 48
    value = 437
    #lock_version = DetailValue.find(value).lock_version.to_i
    new_value = {
                  #:lock_version => lock_version, 
                  :value =>'MOHSIN HIJAZEE'
                }
    ######################################################################
    #                              CASE 01
    #  PUT /instancs/:instance_id/details/:detail_id/values/:id with all ok
    ######################################################################
    put :update, {:format => 'json', 
                  :instance_id => instance, 
                  :detail_id => detail,
                  :id => value,
                  :value => new_value.to_json
                  },
                  {'user' => user}
                
    json = {:errors => ['Provide lock_version for update/delete operations']}.to_json
    assert_response 400    
    assert_equal json, @response.body
    JSON.parse(json)
  end
  
  def test_put_with_setting_value_nil
    user = User.find(@db1_admin_user_id)
    
    instance = 90
    detail = 48
    value = 437
    lock_version = DetailValue.find(value).lock_version.to_i
    new_value = {:lock_version => lock_version, :value => nil}
    ######################################################################
    #                              CASE 01
    #  PUT /instancs/:instance_id/details/:detail_id/values/:id with all ok
    ######################################################################
    pre_count = DetailValue.count
    put :update, {:format => 'json', 
                  :instance_id => instance, 
                  :detail_id => detail,
                  :id => value,
                  :value => new_value.to_json
                  },
                  {'user' => user}

    post_count = DetailValue.count
    #assert_equal ' sdf asdf',  @response.body
    assert_response :success
    assert_equal nil, JSON.parse(@response.body)['value']
    assert_equal 1, pre_count - post_count
    

  end
  
  def test_get_and_put_conflict
    user = User.find_by_id @db1_admin_user_id
    
    id = 1200
    detail = 74
    instance = 200
    res_name = 'value'
    res_id = 456
    
    get :show, {:format => 'json', :instance_id => instance, :detail_id => detail, :id => id}, {'user' => user}
    resource = JSON.parse(@response.body)
    
    resource['value'] = 'GET AND PUT TEST'
    resource['url'] = 'http://localhost:300/values/' + res_id.to_s + '.json'
    
    json = {:errors => ["Requested ID is #{id} and ID in resource is #{res_id}. Are you dispatching your resource at the right location?"]}.to_json
    put :update, {:format => 'json', :id => id, res_name => resource.to_json}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
  end
  
  def test_get_and_put_version_conflict
    
     
    user = User.find_by_id @db1_admin_user_id
    
    instance = 200
    detail = 74
    id = 1200
    res_name = 'value'
    
    get :show, {:detail_id => detail, :format => 'json', :id => id}, {'user' => user}
    #assert_equal '', @response.body
    resource1 = JSON.parse(@response.body)
    
    
    resource1['value'] = 'GET AND PUT TEST'
    
    get :show, {:detail_id => detail, :format => 'json', :id => id}, {'user' => user}
    resource2 = JSON.parse(@response.body)
    
    resource2['value'] = 'GET AND PUT TEST979'
    
    put :update, {
                    :format => 'json', 
                    #:instance_id => instance,
                    :detail_id => detail,
                    :lock_version => resource1['lock_version'], 
                    :id => id, 
                    res_name => resource1.to_json},
                    {'user' => user}
    #assert_equal '', @response.body
    assert_response 200
    new_val = JSON.parse(@response.body)
    assert_equal resource1['value'], new_val['value']
    
    msg = 'Attempted to update a stale object'
    put :update, {
                    :format => 'json', 
                    #:instance_id => instance,
                    :detail_id => detail,
                    :lock_version => resource2['lock_version'],
                    :id => id, 
                    res_name => resource2.to_json
                  }, 
                  {'user' => user}
    assert_response 409
    assert_equal msg, JSON.parse(@response.body)['message']
    
    
    
    
  end  
  
  def test_delete
    # CASE 01: /instances/:instance_id/details/:detail_id/values/:id with all ok
    # CASE 02: /instances/:instance_id/details/:detail_id/values/:id wrong detail
    # CASE 03: /instances/:instance_id/details/:detail_id/values/:id wrong instance
    # CASE 04: /instances/:instance_id/details/:detail_id/values/:id with all irrelevatnt
    
    
    user = User.find @db1_admin_user_id
    
    instance = 90
    detail = 48
    value = 437
    lock_version = DetailValue.find(value).lock_version.to_i
    ###################################################################
    #                          CASE 01
    #   DELETE /instances/:instance_id/details/:detail_id/values/:id with all ok
    ###################################################################
    pre_count = DetailValue.count
    delete :destroy, {:format => 'json', 
                      :instance_id => instance, 
                      :detail_id => detail,
                      :id => value,
                      :lock_version => lock_version
                    },
                      {'user' => user}
    post_count = DetailValue.count
    assert_response :success
    assert_equal 1, pre_count - post_count
    
    instance = 90
    detail = 48
    value = 98879 #437
    lock_version = 9797
    ###################################################################
    #                          CASE 02
    #   DELETE /instances/:instance_id/details/:detail_id/values/:id with wrong value id
    ###################################################################
    json = {:errors => [ "#{Detail.find(detail).data_type.class_name}[#{value}] does not exists"]}.to_json
    pre_count = DetailValue.count
    delete :destroy, {:format => 'json', 
                      :instance_id => instance, 
                      :detail_id => detail,
                      :id => value,
                      :lock_version => lock_version
                    },
                      {'user' => user}
    post_count = DetailValue.count
    assert_response 404
    assert_equal 0, pre_count - post_count
    assert_equal json, @response.body
    
    instance = 90
    detail = 979 #48
    value = 437
    lock_version = 9797
    ###################################################################
    #                          CASE 03
    #   DELETE /instances/:instance_id/details/:detail_id/values/:id with wrong detail id
    ###################################################################
    json = {:errors => [ "Detail[#{detail}] does not exists"]}.to_json
    pre_count = DetailValue.count
    delete :destroy, {:format => 'json', 
                      :instance_id => instance, 
                      :detail_id => detail,
                      :id => value,
                      :lock_version => lock_version
                    },
                      {'user' => user}
    post_count = DetailValue.count
    assert_response 404
    assert_equal 0, pre_count - post_count
    assert_equal json, @response.body
    
    instance = 9799 #90
    detail = 48
    value = 437
    lock_version = 7979
    ###################################################################
    #                          CASE 03
    #   DELETE /instances/:instance_id/details/:detail_id/values/:id with wrong instance id
    ###################################################################
    json = {:errors => [ "Instance[#{instance}] does not exists"]}.to_json
    pre_count = DetailValue.count
    delete :destroy, {:format => 'json', 
                      :instance_id => instance, 
                      :detail_id => detail,
                      :id => value,
                      :lock_version => lock_version
                    },
                      {'user' => user}
    post_count = DetailValue.count
    assert_response 404
    assert_equal 0, pre_count - post_count
    assert_equal json, @response.body
    
    instance = 200
    detail = 74
    value = 1208
    lock_version = DetailValue.find(value).lock_version.to_i
    ######################################################################
    #                              CASE 04
    #  DELETE /instancs/:instance_id/details/:detail_id/values/:id all irrelevant
    ######################################################################
    json = {:errors =>  ["Value[#{value}] does not belong to Detail[#{detail}] and Instance[#{instance}]"]}.to_json
    delete :destroy, {:format => 'json', 
                  :instance_id => instance, 
                  :detail_id => detail,
                  :id => value,
                  :lock_version => lock_version
                  },
                  {'user' => user}
                
    assert_response 400
    assert_equal json, @response.body
    
    
    
  end
  
  def test_delete_with_version_conflict
    # Get a resource
    # Get its lock version
    # modify resource
    # post it back
    user = User.find_by_id @db1_admin_user_id
    
    id = 1200
    detail = 74
    res_name = 'value'
    lock_version = nil
    klass = DetailValue
    
    get :show, {:format => 'json', :detail_id => detail, :id => id}, {'user' => user}
    resource = JSON.parse(@response.body)
    
    lock_version = resource['lock_version']
    
    # PUT it back
    put :update, {:format => 'json', :detail_id => detail, res_name => resource.to_json, :id => id}, {'user' => user}
    #assert_equal '', @response.body
    assert_response 200
    
    msg = 'Attempted to delete a stale object'
    pre_count = klass.count
    delete :destroy, {:format => 'json', :detail_id => detail, :id => id, :lock_version => lock_version}, {'user' => user}
    post_count = klass.count
    assert_response 409
    assert_equal 0, post_count - pre_count
    assert_equal msg, JSON.parse(@response.body)['message']
  end  
  
  
  
  ###################################################################
  # HELPER mehtods.
  ###################################################################
  
  def get_all_values(instance_id, detail_id)
    values = nil
    detail = Detail.find(detail_id)
    condition = ["instance_id = ? AND detail_id = ?", instance_id, detail_id]
    
    values = class_from_name(detail.data_type.class_name).find(:all, :conditions => condition)
      
    return values
  end
  
  def get_single_value(detail_id, value_id)
    value = nil
    
    detail = Detail.find(detail_id, :include => :data_type)
    
    value = class_from_name(detail.data_type.class_name).find(value_id)
    
    return value
   
  end
  
  
end
  
  
