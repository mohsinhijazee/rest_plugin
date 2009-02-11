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
require 'rest/propositions_controller'

require 'json'
# assert_response status_code
# assert_redirect
# assert_redirect_to
# Re-raise errors caught by the controller.
class Rest::PropositionsController; def rescue_action(e) raise e end; end


class Rest::Propositions < Test::Unit::TestCase
  
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
    @controller   = Rest::PropositionsController.new
    @request      = ActionController::TestRequest.new
    @response      = ActionController::TestResponse.new
    
    @db1_admin_user_id = 2
  end
  
  def test_without_login
    # FIXME: Will be rewritten after REST Auth
    assert true
#    id = 1
#    get :show, {:format => 'json', :id => id}, {'user' => nil}
#    assert_response 401
#    json = %Q~{"errors": ["Please login to consume the REST API"]}~
#    assert_equal json, @response.body  
  end
  
  def test_accessing_irrelevant_item
    res_id = 1000
    res_name = 'DetailValueProposition'
    user = User.find @db1_admin_user_id
    json = {:errors =>["#{res_name}[#{res_id}] does not belong to User[#{user.id}] (\"#{user.login}\")"]}.to_json
    get :show, {:format => 'json', :id => res_id}, {'user' => user}
    assert_equal json, @response.body
    
    # Case 02 Where detail and proposition belong to each other but from another account
    parent = 67 
    res_id = 1000
    res_name = 'Detail'
    user = User.find @db1_admin_user_id
    json = {:errors =>["#{res_name}[#{parent}] does not belong to User[#{user.id}] (\"#{user.login}\")"]}.to_json
    get :show, {:format => 'json', :detail_id => parent, :id => res_id}, {'user' => user}
    assert_equal json, @response.body
    
  end
  
  def test_get_all
    # CASE 01: GET /details/:detail_id/propositions with all ok
    # CASE 02: GET /details/:detail_id/propositions with wrong detail
    # CASE 03: GET /propositions ONLY
    
    user = User.find @db1_admin_user_id
    detail = 78
    ################################################################
    #                           CASE 01
    # GET /details/:detail_id/propositions with all ok
    ################################################################
    json = DetailValueProposition.find(:all, :conditions => ["detail_id=?", detail])
    get :index, {:format => 'json', :detail_id => detail}, {'user' => user}
    assert_response :success
    result = JSON.parse(@response.body)
    assert_equal json.length, result['resources'].length
    
    
    detail = 9799 #78
    ################################################################
    #                           CASE 02
    # GET /details/:detail_id/propositions with wrong detail
    ################################################################
    json = {:errors => ["Detail[#{detail}] does not exists"]}.to_json
    get :index, {:format => 'json', :detail_id => detail}, 
      {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    #JSON.parse(json)
    
    detail = 78
    ################################################################
    #                           CASE 03
    # GET /propositions ONLY
    ################################################################
    json = {:errors => ['GET /propositions is not allowed. Use GET /details/:detail_id/propositions instead']}.to_json
    get :index, {:format => 'json'}, 
      {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    
  end
  
  def test_get_all_with_pagination
    # CASE 01: Mention of start_index and max_results
    # CASE 02: Mention of Order by with direction
    # CASE 03: Mention of Order by without direction
    # CASE 04: Mention a condition also
    
    user = User.find_by_id(@db1_admin_user_id)
    
    parent_resource = :detail_id
    parent_id = 78
    start_index = 0
    max_results = 3
    order_by = 'name'
    direction = 'DESC'
    table_name = 'detail_value_propositions'
    conditions = "detail_id=#{parent_id}"
    #total_records = Detail.count_by_sql "SELECT COUNT(*) FROM  #{table_name} WHERE #{conditions}"
    conditions = 'id=50'
    
    total_records = DetailValueProposition.count(:conditions => 'detail_id=78')
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
    
    conditions = "value='Fiction'"
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
    # CASE 01: GET /propositons/:id with all ok
    # CASE 02: GET /propositons/:id with wrong id
    # CASE 03: GET /details/propositons/:id with all ok
    # CASE 04: GET /details/propositons/:id with wrong prop id
    # CASE 05: GET /details/propositons/:id with wrong detail id
    # CASE 06: GET /details/propositons/:id with bot irrelevant
    
    user = User.find @db1_admin_user_id
    
    detail = 78
    prop = 1006
    ################################################################
    #                           CASE 01
    # GET /propositons/:id with all ok
    ################################################################
    model = DetailValueProposition.find(prop)
    get :show, {:format => 'json', :id => prop}, {'user' => user}
    #assert_equal '', @response.body
    assert_response :success
    assert_similar model, @response.body
    
    
    detail = 78
    prop = 87979 #1006
    ################################################################
    #                           CASE 02
    # GET /propositons/:id with wrong prop id
    ################################################################
    json = {:errors => ["DetailValueProposition[#{prop}] does not exists"]}.to_json
    get :show, {:format => 'json', :id => prop}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    #JSON.parse(json)
    
    detail = 78
    prop = 1006
    ################################################################
    #                           CASE 03
    # GET /details/propositons/:id with all ok
    ################################################################
    model = DetailValueProposition.find(prop)
    get :show, {:format => 'json', :detail_id => detail, :id => prop}, 
      {'user' => user}
    assert_response :success
    assert_similar model, @response.body
    
    
    detail = 78
    prop = 87979 #1006
    ################################################################
    #                           CASE 04
    # GET /details/propositons/:id with wrong prop id
    ################################################################
    json = {:errors => ["DetailValueProposition[#{prop}] does not exists"]}.to_json
    get :show, {:format => 'json', :detail_id => detail, :id => prop}, 
      {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    #JSON.parse(json)
    
    detail = 979719 #78
    prop = 1006
    ################################################################
    #                           CASE 05
    # GET /details/propositons/:id with wrong detail
    ################################################################
    json = {:errors => ["Detail[#{detail}] does not exists"]}.to_json
    get :show, {:format => 'json', :detail_id => detail, :id => prop},
      {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    #JSON.parse(json)
    
    detail = 62 #78
    prop = 1006
    ################################################################
    #                           CASE 06
    # GET /details/propositons/:id with both not belong to each other
    ################################################################
    json = {:errors => ["DetailValueProposition[#{prop}] does not belong to Detail[#{detail}]"]}.to_json
    get :show, {:format => 'json', :detail_id => detail, :id => prop}, 
      {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    #JSON.parse(json)
    
    
  end
  
  def test_post
    # CASE 01: POST /propsitions
    # CASE 02: POST /propositions with resource missing
    # CASE 03: POST /propositions with wrong detail mentioned in resource
    # CASE 04: POST /propositions with detail not of Ddl type.
    # CASE 05: POST /propositions with detail missing
    
    user = User.find @db1_admin_user_id
    
    detail = 78
    values = ['Mohsin', 'Ruby', 'Python', 'Java', 'Groovy']
    props = {:detail_id => detail}
    props[:value] = values
    
    ##############################################################
    #                       CASE 01
    #  POST /propositions with all ok
    ##############################################################
    pre_count = DetailValueProposition.count
    post :create, {:format => 'json', :detail_value_proposition => props.to_json}, 
      {'user' => user}
    post_count = DetailValueProposition.count
    assert_response 201
    

    json = JSON.parse(@response.body)

    assert_equal Array, json.class
    assert_equal 5, json.length
    assert_equal 5, post_count - pre_count
    #assert_equal '', @response.body
    
    ##############################################################
    #                       CASE 02
    #  POST /propositions with resource missing
    ##############################################################
    json = {:errors => ['Provide propositions resource to be created/updated']}.to_json
    post :create, {:format => 'json'}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    
    detail = 987987 #78
    props[:detail_id] = detail
    ##############################################################
    #                       CASE 03
    #  POST /propositions inexistant detail
    ##############################################################
    json = {:errors => ["Detail[#{detail}] does not exists"]}.to_json
    post :create, {:format => 'json', :detail_value_proposition => props.to_json},
      {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    
    detail = 74 #78
    props[:detail_id] = detail
    ##############################################################
    #                       CASE 4
    #  POST /propositions with detail of not type madb_choose_in_list
    ##############################################################
    json = {:errors => ["Detail[#{detail}] is not of type madb_choose_in_list"]}.to_json
    post :create, {:format => 'json', :detail_value_proposition => props.to_json},
      {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    
    detail = nil #78
    props[:detail_id] = detail
    ##############################################################
    #                       CASE 05
    #  POST /propositions with no mention of detail
    ##############################################################
    json = {:errors => ['Provide the detail id as detail_id in propositions resource or make a nested call']}.to_json
    post :create, {:format => 'json', :detail_value_proposition => props.to_json},
      {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    
  end
  
  def test_post_with_detail
    # CASE 01: POST /details/propositions with all ok
    # CASE 02: POST /details/propositions with wrong detail
    # CASE 03: POST /details/propositions detail that is not Ddl
    # CASE 04: POST /details/propositions with missing resource
    # CASE 05: POST /details/propostions where detail id is not part of resource
    
    detail = 78
    values = ['Mohsin', 'Ruby', 'Python', 'Java', 'Groovy']
    props = {:detail_id => detail}
    props[:value] = values
    
    user = User.find @db1_admin_user_id
    ##############################################################
    #                       CASE 01
    #  POST /propositions with all ok
    ##############################################################
    pre_count = DetailValueProposition.count
    post :create, {:format => 'json', :detail_id => detail, :detail_value_proposition => props.to_json}, 
      {'user' => user}
    post_count = DetailValueProposition.count
    assert_response 201
    json = JSON.parse(@response.body)
    assert_equal Array, json.class
    assert_equal 5, json.length
    assert_equal 5, post_count - pre_count
    #assert_equal '', @response.body
    
    detail = 7987987 #78
    props[:detail_id] = detail
    ##############################################################
    #                       CASE 02
    #  POST /propositions inexistant detail
    ##############################################################
    json = {:errors => ["Detail[#{detail}] does not exists"]}.to_json
    post :create, {:format => 'json', :detail_id => detail, :detail_value_proposition => props.to_json},
      {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    
    
    detail = 74 #78
    props[:detail_id] = detail
    ##############################################################
    #                       CASE 03
    #  POST /propositions with detail of not type madb_choose_in_list
    ##############################################################
    json = {:errors => ["Detail[#{detail}] is not of type madb_choose_in_list"]}.to_json
    post :create, {:format => 'json', :detail_id => detail, :detail_value_proposition => props.to_json},
      {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    
    ##############################################################
    #                       CASE 04
    #  POST /propositions with resource missing
    ##############################################################
    json = {:errors => ['Provide propositions resource to be created/updated']}.to_json
    post :create, {:format => 'json', :detail_id => detail},
      {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    
    detail = nil #78
    props[:detail_id] = detail
    ##############################################################
    #                       CASE 05
    #  POST /propositions with no mention of detail
    ##############################################################
    json = {:errors => ['Provide the detail id as detail_id in propositions resource or make a nested call']}.to_json
    post :create, {:format => 'json', :detail_id => detail, :detail_value_proposition => props.to_json},
      {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    
    
    
    
    
  end
 
  def test_put
    # CASE 01: PUT /propositons/:id with all ok
    # CASE 02: PUT /propositons/:id with wrong id
    # CASE 03: PUT /details/propositons/:id with all ok
    # CASE 04: PUT /details/propositons/:id with wrong prop id
    # CASE 05: PUT /details/propositons/:id with wrong detail id
    # CASE 06: PUT /details/propositons/:id with bot irrelevant
    
    user = User.find @db1_admin_user_id
    
    detail = 78
    prop = 1006
    res = {:value => 'History'}
    res[:lock_version] = DetailValueProposition.find(prop).lock_version.to_i
    ################################################################
    #                           CASE 01
    # PUT /propositons/:id with all ok
    ################################################################
    put :update, {:format => 'json', :id => prop, :detail_value_proposition => res.to_json}, 
      {'user' => user}
    model = DetailValueProposition.find(prop)
    #assert_equal '', @response.body 
    assert_response :success
    assert_similar model, @response.body
    
    
    detail = 78
    prop = 87979 #1006
    res[:lock_version] = 7979
    ################################################################
    #                           CASE 02
    # GET /propositons/:id with wrong prop id
    ################################################################
    json = {:errors => ["DetailValueProposition[#{prop}] does not exists"]}.to_json
    put :update, {:format => 'json', :id => prop, :detail_value_proposition => res.to_json}, 
      {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    #JSON.parse(json)
    
    detail = 78
    prop = 1006
    res[:lock_version] = DetailValueProposition.find(prop).lock_version.to_i
    ################################################################
    #                           CASE 02
    # GET /propositons/:id with wrong prop id
    ################################################################
    json = {:errors => ['Provide propositions resource to be created/updated']}.to_json
    put :update, {:format => 'json', :id => prop}, 
      {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    #JSON.parse(json)
    

  end
  
  def test_put_without_lock_version
    
    user = User.find(@db1_admin_user_id)
        detail = 78
    prop = 1006
    res = {:value => 'History'}
    #res[:lock_version] = DetailValueProposition.find(prop).lock_version.to_i
    ################################################################
    #                           CASE 01
    # PUT /propositons/:id without lock_version
    ################################################################
    put :update, {:format => 'json', :id => prop, :detail_value_proposition => res.to_json}, 
      {'user' => user}
    json = {:errors => ['Provide lock_version for update/delete operations']}.to_json
    assert_response 400
    assert_equal json, @response.body
    JSON.parse(json)
    
    
  end
  
  
  def test_put_with_detail
        
    user = User.find @db1_admin_user_id
    res = {:value => 'History'}
    
    detail = 78
    prop = 1006
    res[:lock_version] = DetailValueProposition.find(prop).lock_version.to_i
    ################################################################
    #                           CASE 03
    # PUT /details/propositons/:id with all ok
    ################################################################
    put :update, {:format => 'json', :detail_id => detail, :id => prop, :detail_value_proposition => res.to_json}, 
      {'user' => user}
    model = DetailValueProposition.find(prop)
    assert_response :success
    assert_similar model, @response.body
    
    
    detail = 78
    prop = 87979 #1006
    res[:lock_version] = 7979
    ################################################################
    #                           CASE 04
    # GET /details/propositons/:id with wrong prop id
    ################################################################
    json = {:errors => ["DetailValueProposition[#{prop}] does not exists"]}.to_json
    put :update, {:format => 'json', :detail_id => detail, :id => prop, :detail_value_proposition => res.to_json}, 
      {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    #JSON.parse(json)
    
    detail = 979719 #78
    prop = 1006
    res[:lock_version] = DetailValueProposition.find(prop).lock_version.to_i
    ################################################################
    #                           CASE 05
    # GET /details/propositons/:id with wrong detail
    ################################################################
    json = {:errors => ["Detail[#{detail}] does not exists"]}.to_json
    put :update, {:format => 'json', :detail_id => detail, :id => prop, :detail_value_proposition => res.to_json}, 
      {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    #JSON.parse(json)
    
    detail = 62 #78
    prop = 1006
    res[:lock_version] = DetailValueProposition.find(prop).lock_version.to_i
    ################################################################
    #                           CASE 06
    # GET /details/propositons/:id with both not belong to each other
    ################################################################
    json = {:errors => ["DetailValueProposition[#{prop}] does not belong to Detail[#{detail}]"]}.to_json
    put :update, {:format => 'json', :detail_id => detail, :id => prop, :detail_value_proposition => res.to_json},
      {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    #JSON.parse(json)
    
    detail = 78
    prop = 1006
    res[:lock_version] = DetailValueProposition.find(prop).lock_version.to_i
    ################################################################
    #                           CASE 05
    # GET /details/propositons/:id with wrong detail
    ################################################################
    json = {:errors => ['Provide propositions resource to be created/updated']}.to_json
    put :update, {:format => 'json', :detail_id => detail, :id => prop}, 
      {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    #JSON.parse(json)
    
  end
  
  def test_get_and_put
    user = User.find_by_id @db1_admin_user_id
    
    id = 1006
    res_name = 'detail_value_proposition'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource = JSON.parse(@response.body)
    
    resource['value'] = 'GET AND PUT TEST'
    
    put :update, {:format => 'json', :id => id, res_name => resource.to_json}, {'user' => user}
    assert_response 200
    new_val = JSON.parse(@response.body)
    assert_equal resource['value'], new_val['value']    
    
  end
  
  def test_get_and_put_conflict
    user = User.find_by_id @db1_admin_user_id
    
    id = 1006
    res_id = 78
    res_name = 'detail_value_proposition'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource = JSON.parse(@response.body)
    
    resource['value'] = 'GET AND PUT TEST'
    resource['url'] = 'http://localhost:300/databases/' + res_id.to_s + '.json'
    
    json = {:errors => ["Requested ID is #{id} and ID in resource is #{res_id}. Are you dispatching your resource at the right location?"]}.to_json
    put :update, {:format => 'json', :id => id, res_name => resource.to_json}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
  end
  
  def test_get_and_put_version_conflict
    user = User.find_by_id @db1_admin_user_id
    
    id = 1007
    res_name = 'detail_value_proposition'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource1 = JSON.parse(@response.body)
    
    resource1['value'] = 'GET AND PUT TEST'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource2 = JSON.parse(@response.body)
    
    resource2['value'] = 'GET AND PUT TEST8'
    
    put :update, {:format => 'json', :id => id, res_name => resource1.to_json}, {'user' => user}
    #assert_equal '', @response.body
    assert_response 200
    new_val = JSON.parse(@response.body)
    assert_equal resource1['value'], new_val['value']    
    
    msg ="Attempted to update a stale object"
    put :update, {:format => 'json', :id => id, res_name => resource2.to_json}, {'user' => user}
    assert_response 409

    assert_equal msg, JSON.parse(@response.body)['message']

    
    
    
    
  end
  
  
  def test_delete
    # CASE 01: DELETE /propositons/:id with all ok
    # CASE 02: DELETE /propositons/:id with wrong id
    # CASE 03: DELETE /details/propositons/:id with all ok
    # CASE 04: DELETE /details/propositons/:id with wrong prop id
    # CASE 05: DELETE /details/propositons/:id with wrong detail id
    # CASE 06: DELETE /details/propositons/:id with bot irrelevant
    
    user = User.find @db1_admin_user_id
    
    detail = 78
    prop = 1006
    lock_version = DetailValueProposition.find(prop).lock_version.to_i
    ################################################################
    #                           CASE 01
    # GET /propositons/:id with all ok
    ################################################################
    pre_count = DetailValueProposition.count
    delete :destroy, {:format => 'json', :lock_version => lock_version, :id => prop}, 
      {'user' => user}
    post_count = DetailValueProposition.count
    assert_response :success
    assert_equal 1, pre_count - post_count
    
    detail = 78
    prop = 87979 #1006
    lock_version = 7979
    ################################################################
    #                           CASE 02
    # GET /propositons/:id with wrong prop id
    ################################################################
    pre_count = DetailValueProposition.count
    json = {:errors => ["DetailValueProposition[#{prop}] does not exists"]}.to_json
    delete :destroy, {:format => 'json', :lock_version => lock_version, :id => prop}, 
      {'user' => user}
    pre_count = DetailValueProposition.count
    assert_response 404
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    #JSON.parse(json)
    

  end
  
  def test_delete_with_version_conflict
    # Get a resource
    # Get its lock version
    # modify resource
    # post it back
    user = User.find_by_id @db1_admin_user_id
    
    id = 1003
    res_name = 'detail_value_proposition'
    lock_version = nil
    klass = DetailValueProposition
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    assert_response 200
    resource = JSON.parse(@response.body)
    
    #assert_equal '', resource.to_json
    lock_version = resource['lock_version']
    
    # PUT it back
    put :update, {:format => 'json', res_name => resource.to_json, :id => id}, {'user' => user}
    
    msg = 'Attempted to delete a stale object'
    pre_count = klass.count
    delete :destroy, {:format => 'json', :id => id, :lock_version => lock_version}, {'user' => user}
    post_count = klass.count
    #assert_equal '', @response.body
    assert_response 409
    assert_equal 0, post_count - pre_count

    assert_equal msg, JSON.parse(@response.body)['message']

  end
  
  def test_delete_without_lock_version
    
    user = User.find @db1_admin_user_id
    
    #detail = 78
    prop = 1006
    #lock_version = DetailValueProposition.find(prop).lock_version.to_i
    ################################################################
    #                           CASE 01
    # GET /propositons/:id with all ok
    ################################################################
    pre_count = DetailValueProposition.count
    json = {:errors => ['Provide lock_version for update/delete operations']}.to_json
    delete :destroy, {:format => 'json',  :id => prop}, {'user' => user}
    post_count = DetailValueProposition.count
    assert_response 400
    assert_equal json, @response.body
    assert_equal 0, pre_count - post_count
    
    

  end
  
  def test_delete_with_detail
    
    user = User.find @db1_admin_user_id
    
    detail = 78
    prop = 87979 #1006
    lock_version = 9797
    ################################################################
    #                           CASE 04
    # GET /details/propositons/:id with wrong prop id
    ################################################################
    pre_count = DetailValueProposition.count
    json = {:errors => ["DetailValueProposition[#{prop}] does not exists"]}.to_json
    post_count = DetailValueProposition.count
    delete :destroy, {:format => 'json', :lock_version => lock_version, :detail_id => detail, :id => prop}, 
      {'user' => user}
    assert_response 404
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    #JSON.parse(json)
    
    detail = 979719 #78
    prop = 1006
    lock_version = DetailValueProposition.find(prop).lock_version.to_i
    ################################################################
    #                           CASE 05
    # GET /details/propositons/:id with wrong detail
    ################################################################
    pre_count = DetailValueProposition.count
    json = {:errors => ["Detail[#{detail}] does not exists"]}.to_json
    delete :destroy, {:format => 'json', :lock_version => lock_version, :detail_id => detail, :id => prop}, 
      {'user' => user}
    post_count = DetailValueProposition.count
    assert_response 404
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    #JSON.parse(json)
    
    detail = 62 #78
    prop = 1006
    lock_version = DetailValueProposition.find(prop).lock_version.to_i
    ################################################################
    #                           CASE 06
    # GET /details/propositons/:id with both not belong to each other
    ################################################################
    pre_count = DetailValueProposition.count
    json = {:errors => ["DetailValueProposition[#{prop}] does not belong to Detail[#{detail}]"]}.to_json
    delete :destroy, {:format => 'json', :lock_version => lock_version, :detail_id => detail, :id => prop},
      {'user' => user}
    pre_count = DetailValueProposition.count
    assert_response 400
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    #JSON.parse(json)
    
    detail = 78
    prop = 1006
    lock_version = DetailValueProposition.find(prop).lock_version.to_i
    ################################################################
    #                           CASE 03
    # GET /details/propositons/:id with all ok
    ################################################################
    pre_count = DetailValueProposition.count
    delete :destroy, {:format => 'json', :lock_version => lock_version, :detail_id => detail, :id => prop},
      {'user' => user}
    post_count = DetailValueProposition.count
    assert_response :success
    assert_equal 1, pre_count - post_count
    
  end
  
  

  
end
  
  
