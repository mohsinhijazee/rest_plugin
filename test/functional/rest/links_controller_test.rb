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
require 'rest/links_controller'


# assert_response status_code
# assert_redirect
# assert_redirect_to
# Re-raise errors caught by the controller.
class Rest::LinksController; def rescue_action(e) raise e end; end

#NOTE: This controller do not have get_and_put and get_and_put_conflict because
#updates on links is not allowed.
#FIXME: This test does not cover all the possible options for POST
#FIXME: Needs tests for irrelevatn accesss
class LinksControllerTest < Test::Unit::TestCase
  
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
    @controller   = Rest::LinksController.new
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
  
#  def test_accessing_irrelevant_item
#    res_id = 3
#    res_name = 'Account'
#    user = User.find @db1_admin_user_id
#    json = {:errors =>["#{res_name}[#{res_id}] does not belong to User[#{user.id}] (\"#{user.login}\")"]}.to_json
#    get :show, {:format => 'json', :id => 3}, {'user' => user}
#    assert_equal json, @response.body
#  end
#  
  def test_get_all
    # CASE 01: /instance_id/links with all ok
    # CASE 02: /instance_id/links with wrong instance
    # CASE 03: /links only
    
    user = User.find @db1_admin_user_id
    
    instance = 77
    link = 52
    ####################################################################
    #                             CASE 01
    #  GET /links?instacne=id with all ok                            
    ####################################################################
    json = Link.find(:all, :conditions => ["parent_id = ? or child_id = ?", instance, instance])
    get :index , {:format => 'json', :instance_id => instance}, {'user' => user}
    assert_response :success
    result = JSON.parse(@response.body)
    assert_equal json.length, result['resources'].length
    
    
    instance = 9879 #77
    link = 52
    ####################################################################
    #                             CASE 02
    #  GET /links?instacne=id with wrong instance
    ####################################################################
    json = {:errors => ["Instance[#{instance}] does not exists"]}.to_json
    get :index, {:format => 'json', :instance_id => instance}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    
    
    instance = 9879 #77
    link = 52
    ####################################################################
    #                             CASE 03
    #  GET /links?instacne=id with wrong instance
    ####################################################################
    json = {:errors => ['GET /links not allowed, Use GET instances/:instance_id/links instead']}.to_json
    get :index, {:formatm => 'json'}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    
  end
  
  def test_get_all_with_pagination
    # CASE 01: Mention of start_index and max_results
    # CASE 02: Mention of Order by with direction
    # CASE 03: Mention of Order by without direction
    # CASE 04: Mention a condition also
    
    user = User.find_by_id(@db1_admin_user_id)
    
    parent_resource = :instance_id
    parent_id = 77
    start_index = 0
    max_results = 3
    order_by = 'name'
    direction = 'DESC'
    table_name = 'data_types'
    conditions = 'database_id=6'
    #total_records = Detail.count_by_sql "SELECT COUNT(*) FROM  #{table_name} WHERE #{conditions}"
    conditions = 'id=50'
    
    total_records = Link.count :conditions => "parent_id=#{parent_id} or child_id=#{parent_id}"
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
    
    
    
    order_by = 'relation_id'
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
    assert_equal 52, result['resources'][0]['url'].chomp('.json')[/\d+$/].to_i
    
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

    assert_equal max_results, result['resources'].length
    assert_equal 'asc', result['direction']
    assert_equal 42, result['resources'][0]['url'].chomp('.json')[/\d+$/].to_i
    
    conditions = "relation_id=9"
    #########################################################
    #                        CASE 04
    #        Mention of order by specifying condition
    #########################################################
    get :index, {
      parent_resource => parent_id,
      :format => 'json', 
      #:start_index => start_index, 
      #:max_results => max_results,
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
    # CASE 01: GET /links/:id with all ok
    # CASE 02: GET /links/:id with wrong id
    # CASE 03: GET /instance_id/link/:id with all ok
    # CASE 04: GET /instance_id/link/:id with wrong id
    # CASE 05: GET /instance_id/linnk/:id with wrong instance
    # CASE 06: GET /instance_id/link/:id with both unrelated
    
    user = User.find @db1_admin_user_id
    
    instance = 77
    link = 52
    #####################################################################
    #                          CASE 01
    #   GET /links/:id with all ok
    #####################################################################
    model = Link.find(link)
    get :show, {:format => 'json', :id => link}, {'user' => user}
    assert_response :success
    assert_similar model, @response.body
    
    
    instance = 77
    link = 98798 #52
    #####################################################################
    #                          CASE 02
    #   GET /links/:id with all ok
    #####################################################################
    json = {:errors => ["Link[#{link}] does not exists"]}.to_json
    get :show, {:format => 'json', :id => link}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    
    instance = 77
    link = 52
    #####################################################################
    #                          CASE 03
    #   GET /instances/links/:id with all ok
    #####################################################################
    model = Link.find(link)
    get :show, {:format => 'json', :instance_id => instance, :id => link}, {'user' => user}
    assert_response :success
    assert_similar model, @response.body
    
    
    instance = 77
    link = 98798 #52
    #####################################################################
    #                          CASE 04
    #   GET /instances/links/:id with wrong link
    #####################################################################
    json = {:errors => ["Link[#{link}] does not exists"]}.to_json
    get :show, {:format => 'json', :instance_id => instance, :id => link}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    
    instance = 98879 #77
    link = 52
    #####################################################################
    #                          CASE 05
    #   GET /instances/links/:id with wrong instance
    #####################################################################
    json = {:errors => ["Instance[#{instance}] does not exists"]}.to_json
    get :show, {:format => 'json', :instance_id => instance, :id => link}, {'user' => user}
    assert_response 404
    assert_equal json, @response.body
    
    instance = 91  #77
    link = 52
    #####################################################################
    #                          CASE 06
    #   GET /instances/links/:id with both unrelated
    #####################################################################
    json = {:errors => ["Link[#{link}] does not belong to Instance[#{instance}]"]}.to_json
    get :show, {:format => 'json', :instance_id => instance, :id => link}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
    
  end
  
  def test_post
    # CASE 01: /links with link resource
    # CASE 02: /links without link resource
    
    
    user = User.find @db1_admin_user_id
    
    
    relation_id = 9
    child_id = 89
    parent_id = 82
    #################################################################
    #                          CASE 01
    #   POST /links with link resource
    #################################################################
    post_data = %Q~{"relation_id": #{relation_id}, "child_id": #{child_id}, "parent_id": #{parent_id}}~
    pre_count = Link.count
    post :create, {:format => 'json', :link => post_data}, {'user' => user}
    post_count = Link.count
    assert_response 201
    assert_equal 1, post_count - pre_count
    #assert_equal '', @response.body
    
    relation_id = 9
    child_id = 89 #82
    parent_id =82 # 77
    #################################################################
    #                          CASE 02
    #   POST /links without link resource
    #################################################################
    json = {:errors => ['Provide the link paramter to be created/updated']}.to_json
    pre_count = Link.count
    post :create, {:format => 'json'}, {'user' => user}
    post_count = Link.count
    assert_response 400
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
  end
  
  def test_post_with_instance
    # CASE 01: /instances/links with link resource
    # CASE 02: /instances/links without link resource
    # CASE 03: /instances/links with instance wrong
    
    
    
    user = User.find @db1_admin_user_id
    
    link = \
      {
        :relation_url   => 'http://localhost:3000/relations/9.json',
        :parent_url     => 'http://localhost:3000/instances/82.json',
        :child_url      => 'http://localhost:3000/instances/89.json'
      }
    
    instance = 82
    #################################################################
    #                          CASE 01
    #   POST /links with link resource
    #################################################################
    pre_count = Link.count
    post :create, {:format => 'json', :instance_id => instance, :link => link.to_json}, {'user' => user}
    post_count = Link.count
    assert_response 201
    assert_equal 1, post_count - pre_count
    #assert_equal '', @response.body
    
    instance = 82
    #################################################################
    #                          CASE 02
    #   POST /instances/links without link resource
    #################################################################
    json = {:errors => ['Provide the link paramter to be created/updated']}.to_json
    pre_count = Link.count
    post :create, {:format => 'json', :instance_id => instance}, {'user' => user}
    post_count = Link.count
    assert_response 400
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    
    instance = 979748 #82
    #################################################################
    #                          CASE 03
    #   POST /instances/links without link resource
    #################################################################
    json = {:errors => ["Instance[#{instance}] does not exists"]}.to_json
    pre_count = Link.count
    post :create, {:format => 'json', :instance_id => instance, :link => link.to_json}, {'user' => user}
    post_count = Link.count
    assert_response 404
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    

  end
  
  def test_post_with_instance_parent_provided
    # CASE 01: /instances/links with link resource parent separate

    
    
    
    user = User.find @db1_admin_user_id
    
    link = \
      {
        :relation_url   => 'http://localhost:3000/relations/9.json',
        #:parent_url     => 'http://localhost:3000/instances/82.json',
        :child_url      => 'http://localhost:3000/instances/89.json'
      }
    
    instance = 82
    #################################################################
    #                          CASE 01
    #   POST /links with link resource
    #################################################################
    pre_count = Link.count
    post :create, {:format => 'json', :instance_id => instance, :link => link.to_json}, {'user' => user}
    post_count = Link.count
    assert_response 201
    assert_equal 1, post_count - pre_count
    #assert_equal '', @response.body
    
    

  end
  
  def test_post_with_instance_child_provided
    # CASE 01: /instances/links with link resource child separate

    
    
    
    user = User.find @db1_admin_user_id
    
    link = \
      {
        :relation_url   => 'http://localhost:3000/relations/9.json',
        :parent_url     => 'http://localhost:3000/instances/82.json',
        #:child_url      => 'http://localhost:3000/instances/89.json'
      }
    
    instance = 82
    #################################################################
    #                          CASE 01
    #   POST /links with link resource
    #################################################################
    pre_count = Link.count
    post :create, {:format => 'json', :instance_id => instance, :link => link.to_json}, {'user' => user}
    post_count = Link.count
    assert_response 201
    assert_equal 1, post_count - pre_count
    #assert_equal '', @response.body
    
    

  end
  
  def test_put
    #PENDING: # NOTE ALLOWED!
  end
  
  def test_delete
    # CASE 01: DELETE /links/:id with all ok
    # CASE 02: DELETE /links/:id with wrong id
    
    user = User.find @db1_admin_user_id
    
    link = 52
    ##################################################################
    #                       CASE 01
    #   DELETE /links/:id with all ok                    
    ##################################################################
    pre_count = Link.count
    delete :destroy, {:format => 'json', :id => link}, {'user' => user}
    post_count = Link.count
    assert_response :success
    assert_equal 1, pre_count - post_count
    
    link = 9879 #52
    ##################################################################
    #                       CASE 02
    #   DELETE /links/:id with wrong id
    ##################################################################
    json = {:errors => ["Link[#{link}] does not exists"]}.to_json
    pre_count = Link.count
    delete :destroy, {:format => 'json', :id => link}, {'user' => user}
    post_count = Link.count
    assert_response 404
    assert_equal 0, pre_count - post_count
  end
  
    def test_delete_with_instance
    # CASE 01: DELETE /instances/links/:id with all ok
    # CASE 02: DELETE /instancs/links/:id with wrong id
    # CASE 03: DELETE /instancs/links/:id with wrong instance
    # CASE 04: DELETE /instancs/links/:id with with instance line irrelevant
    
    user = User.find @db1_admin_user_id
    
    
    
    instance = 77
    link = 9879 #52
    ##################################################################
    #                       CASE 02
    #   DELETE /links/:id with wrong id
    ##################################################################
    json = {:errors => ["Link[#{link}] does not exists"]}.to_json
    pre_count = Link.count
    delete :destroy, {:format => 'json',:instance_id => instance, :id => link}, {'user' => user}
    post_count = Link.count
    assert_response 404
    assert_equal 0, pre_count - post_count
    assert_equal json, @response.body
    
    instance = 7987 #77
    link = 52
    ##################################################################
    #                       CASE 03
    #   DELETE /links/:id with wrong instance
    ##################################################################
    json = {:errors => ["Instance[#{instance}] does not exists"]}.to_json
    pre_count = Link.count
    delete :destroy, {:format => 'json',:instance_id => instance, :id => link}, {'user' => user}
    post_count = Link.count
    assert_response 404
    assert_equal 0, pre_count - post_count
    assert_equal json, @response.body
        
    instance = 91 #77
    link = 52
    ##################################################################
    #                       CASE 03
    #   DELETE /links/:id with wrong instance
    ##################################################################
    json = {:errors => ["Link[#{link}] does not belong to Instance[#{instance}]"]}.to_json
    pre_count = Link.count
    delete :destroy, {:format => 'json',:instance_id => instance, :id => link}, {'user' => user}
    post_count = Link.count
    assert_response 400
    assert_equal 0, pre_count - post_count
    assert_equal json, @response.body
    
    instance = 77
    link = 52
    ##################################################################
    #                       CASE 01
    #   DELETE /links/:id with all ok                    
    ##################################################################
    pre_count = Link.count
    delete :destroy, {:format => 'json', :instance_id => instance, :id => link}, {'user' => user}
    post_count = Link.count
    assert_response :success
    assert_equal 1, pre_count - post_count
  end
  

end
  
  
