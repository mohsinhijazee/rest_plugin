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
require 'rest/relations_controller'


# assert_response status_code
# assert_redirect
# assert_redirect_to
# Re-raise errors caught by the controller.
class Rest::RelationsController; def rescue_action(e) raise e end; end


class RelationsControllerTest < Test::Unit::TestCase
  
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
    @controller   = Rest::RelationsController.new
    @request      = ActionController::TestRequest.new
    @response      = ActionController::TestResponse.new
    
    @db1_admin_user_id = 2
    @db1_normal_user_id = 1000001
  end
  
  def test_without_login
    # FIXME: will be written later after impelementation of REST auth
    assert true
#    id = 1
#    get :show, {:format => 'json', :id => id}, {'user' => nil}
#    assert_response 401
#    json = %Q~{"errors": ["Please login to consume the REST API"]}~
#    assert_equal json, @response.body  
  end
  
  def test_accessing_irrelevant_item
    res_id = 5
    res_name = 'Relation'
    user = User.find @db1_admin_user_id
    json = {:errors =>["#{res_name}[#{res_id}] does not belong to User[#{user.id}] (\"#{user.login}\")"]}.to_json
    get :show, {:format => 'json', :id => res_id}, {'user' => user}
    assert_equal json, @response.body
    
    res_id = 5
    entity = 7
    res_name = 'Entity'
    user = User.find @db1_admin_user_id
    json = {:errors =>["#{res_name}[#{entity}] does not belong to User[#{user.id}] (\"#{user.login}\")"]}.to_json
    get :show, {:format => 'json', :entity_id => entity, :id => res_id}, {'user' => user}
    assert_equal json, @response.body
  end
  
  def test_accessing_without_adminstrative_rights
    # FIXME: Needs a redo after REST auth
    assert true
#    user  = User.find @db1_normal_user_id
#    parent = :entity_id
#    parent_id = 12
#    id = 7
#    
#    get :index, {:format => 'json', parent => parent_id}, {'user' => user}
#    assert_response 200
#    
#    get :show, {:format => 'json', :id => id}, {'user' => user}
#    assert_response 200
#    
#    resource_name = :relation
#    resource = %Q~{"name": "asf"}~
#    msg = {:errors => ['This REST call needs administrative rights']}
#    
#    post :create, {:format => 'json', resource_name => resource}, {'user' => user}
#    #assert_equal '', @response.body
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
    
  end
  
  
  def test_get_all
    # CASE 01: GET entities/:entity_id/relations with all ok
    # CASE 02: GET entities/:entity_id/relations entity is wrong
    # CASE 03: GET /relations
    
    user = User.find @db1_admin_user_id
    
    
    
    entity = 52
    db = 8
    #################################################################
    #                           CASE 01
    #  GET /relations?entity
    #################################################################
    get :index, {:format => 'json', :entity_id => entity}, { 'user' => user }
    json = Relation.find(:all, :conditions => ["parent_id = ? or child_id = ?", entity, entity])
    assert_response :success
    result = JSON.parse(@response.body)
    assert_equal json.length, result['resources'].length
    
    
    entity = 6446 #52
    db = 8
    #################################################################
    #                           CASE 02
    #  GET /relations?entity with wrong entity
    #################################################################
    get :index, {:format => 'json', :entity_id => entity}, { 'user' => user }
    json = {:errors => ["Entity[#{entity}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body
    
    entity = 52
    db = 8
    #################################################################
    #                           CASE 03
    #  GET /relations with out specifying entity
    #################################################################
    get :index, {:format => 'json'}, { 'user' => user }
    json = {:errors => ['GET /relatiosn is not allowed, use GET /entities/:entity_id/relations instead']}.to_json
    assert_response 400
    assert_equal json, @response.body
    
  end
  
  def test_get_all_with_pagination
    # CASE 01: Mention of start_index and max_results
    # CASE 02: Mention of Order by with direction
    # CASE 03: Mention of Order by without direction
    # CASE 04: Mention a condition also
    
    user = User.find_by_id(@db1_admin_user_id)
    
    parent_resource = :entity_id
    parent_id = 12
    start_index = 0
    max_results = 2
    order_by = 'name'
    direction = 'DESC'
    table_name = 'data_types'
    conditions = 'database_id=6'
    #total_records = Detail.count_by_sql "SELECT COUNT(*) FROM  #{table_name} WHERE #{conditions}"
    conditions = 'id=50'
    
    total_records = Relation.count :conditions => "parent_id=#{parent_id} or child_id=#{parent_id}"
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

    result = JSON.parse(result)

    assert_equal max_results, result['resources'].length
    assert_equal total_records, result['total_resources']
    
    
    
    order_by = 'from_parent_to_child_name'
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
    assert_equal 9, result['resources'][0]['url'].chomp('.json')[/\d+$/].to_i
    
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
    assert_equal 7, result['resources'][0]['url'].chomp('.json')[/\d+$/].to_i
    
    conditions = "from_parent_to_child_name='contact_de_visite'"
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
  
#  def test_get_all_with_entity
#    # CASE 01: GET /entities/relation with all ok
#    # CASE 02: GET /entities/relations with wrong entity
#    
#    user = User.find @db1_admin_user_id
#    
#    entity = 52
#    db = 8
#    #################################################################
#    #                           CASE 01
#    #  GET /relations?entity
#    #################################################################
#    get :index, {:format => 'json', :entity_id => entity}, { 'user' => user }
#    json = Relation.find(:all, :conditions => ["parent_id = ? or child_id = ?", entity, entity]).to_json(:format => 'json')
#    assert_response :success
#    assert_equal json, @response.body
#    JSON.parse(json)
#    
#    entity = 7987 #52
#    db = 8
#    #################################################################
#    #                           CASE 02
#    #  GET /entities/relations
#    #################################################################
#    get :index, {:format => 'json', :entity_id => entity}, { 'user' => user }
#    json = {:errors => ["Entity[#{entity}] does not exists"]}.to_json
#    assert_response 404
#    assert_equal json, @response.body
#    
#  end
  
  # *WARNING* /databases/entities/relations NO MORE ALLOWED!
#  def test_get_all_with_database_entity
#    # CASE 01: GET /databases/entities/realtions with all ok
#    # CASE 02: GET /databases/entities/relations with wrong entity
#    # CASE 03: GET /databases/entities/relations with wrong database
#    # CASE 04: GET /databases/entities/realtions with unrelated items
#    
#    user = User.find @db1_admin_user_id
#    
#    entity = 52
#    db = 8
#    ################################################################
#    #                           CASE 01
#    #  GET /databases/entities/relations with all ok
#    ################################################################
#    get :index, {:format => 'json', :database_id => db, :entity_id => entity}, { 'user' => user }
#    json = Relation.find(:all, :conditions => ["parent_id = ? or child_id = ?", entity, entity]).to_json(:format => 'json')
#    assert_response :success
#    assert_equal json, @response.body
#    
#    entity = 987 #52
#    db = 8
#    ################################################################
#    #                           CASE 02
#    #  GET /databases/entities/relations with wrong entity
#    ################################################################
#    get :index, {:format => 'json', :database_id => db, :entity_id => entity}, { 'user' => user }
#    json = "Entity[#{entity}] does not exists"
#    assert_response 400
#    assert_equal json, @response.body
#    
#    entity = 52
#    db = 5787 #8
#    ################################################################
#    #                           CASE 03
#    #  GET /databases/entities/relations with wrong database
#    ################################################################
#    get :index, {:format => 'json', :database_id => db, :entity_id => entity}, { 'user' => user }
#    json = "Database[#{db}] does not exists"
#    assert_response 400
#    assert_equal json, @response.body
#    
#    entity = 52
#    db = 5787 #8
#    ################################################################
#    #                           CASE 04
#    #  GET /databases/entities/relations with unrelated items
#    ################################################################
#    get :index, {:format => 'json', :database_id => db, :entity_id => entity}, { 'user' => user }
#    json = "Entity[#{entity}] does not belongs to Database[#{db}]"
#    assert_response 400
#    assert_equal json, @response.body
#    
#  end
  
  def test_get_single
    # CASE 01: GET /relations/:id with all ok
    # CASE 02: GET /relations/:id with wrong id
    
    user = User.find @db1_admin_user_id
    
    relation = 7
    entity =12
    db = 6
    ###################################################################
    #                             CASE 01
    #  GET /relations/:id with all ok
    ###################################################################
    get :show, {:format => 'json', :id => relation}, {'user' => user}
    
    model = Relation.find(relation)
    assert_response :success
    assert_similar model, @response.body

    
    relation = 7987 #7
    entity =12
    db = 6
    ###################################################################
    #                             CASE 02
    #  GET /relations/:id with wrong id
    ###################################################################
    get :show, {:format => 'json', :id => relation}, {'user' => user}
    json = {:errors => ["Relation[#{relation}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body
    
  end
  
  def test_get_single_with_entity
    # CASE 01: GET /entities/relations/:id with all ok
    # CASE 02: GET /entities/relations/:id with wrong relation
    # CASE 03: GET /entities/relations/:id with wrong entity
    # CASE 04: GET /entities/relations/:id relation entity unrealted
    
    user = User.find @db1_admin_user_id
    
    relation = 7
    entity = 12
    db = 6
    ##################################################################
    #                          CASE 01
    #   GET /entities/relations/:id with all ok
    ##################################################################
    model = Relation.find(relation)
    get :show, {:format => 'json', :entity_id => entity, :id => relation}, { 'user' => user}
    assert_response :success
    assert_similar model, @response.body
    
    
    relation = 9879 #7
    entity = 12
    db = 6
    ##################################################################
    #                          CASE 02
    #   GET /entities/relations/:id with wrong relation
    ##################################################################
    json = {:errors => ["Relation[#{relation}] does not exists"]}.to_json
    get :show, {:format => 'json', :entity_id => entity, :id => relation}, { 'user' => user}
    assert_response 404
    assert_equal json, @response.body
    
    relation = 7
    entity = 979 #12
    db = 6
    ##################################################################
    #                          CASE 03
    #   GET /entities/relations/:id with wrong entity
    ##################################################################
    json = {:errors => ["Entity[#{entity}] does not exists"]}.to_json
    get :show, {:format => 'json', :entity_id => entity, :id => relation}, { 'user' => user}
    assert_response 404
    assert_equal json, @response.body
    
    relation = 7
    entity = 52 #12
    db = 6
    ##################################################################
    #                          CASE 04
    #   GET /entities/relations/:id with unrelated items
    ##################################################################
    json = {:errors => ["Relation[#{relation}] does not belong to Entity[#{entity}]"]}.to_json
    get :show, {:format => 'json', :entity_id => entity, :id => relation}, { 'user' => user}
    assert_response 400
    assert_equal json, @response.body
    
  end

# *WARNING*  GET /databases/entities/relations/:id NOT ALLOWED!
#  def test_get_single_with_database_entity
#    # CASE 01: GET /databases/entities/relations/:id with all ok
#    # CASE 02: GET /databases/entities/relations/:id with wrong relation
#    # CASE 03: GET /databases/entities/relations/:id with wrong entity
#    # CASE 04: GET /databases/entities/relations/:id with wrong database
#    # CASE 05: GET /databases/entities/relations/:id with unrelated entity relation
#    # CASE 06: GET /databases/entities/relations/:id with unrelated database entity
#    
#    user = User.find @db1_admin_user_id
#    
#    relation = 7
#    entity = 12
#    db = 6
#    ##################################################################
#    #                          CASE 01
#    #   GET /databases/entities/relations/:id with all ok
#    ##################################################################
#    json = Relation.find(relation).to_json(:format => 'json')
#    get :show, {:format => 'json', :database_id => db, :entity_id => entity, :id => relation}, { 'user' => user}
#    assert_response :success
#    assert_equal json, @response.body
#    
#    relation = 978 #7
#    entity = 12
#    db = 6
#    ##################################################################
#    #                          CASE 02
#    #   GET /databases/entities/relations/:id with wrong relation
#    ##################################################################
#    json = "Relation[#{relation}] does not exists"
#    get :show, {:format => 'json', :database_id => db, :entity_id => entity, :id => relation}, { 'user' => user}
#    assert_response 400
#    assert_equal json, @response.body
#    
#    relation = 7
#    entity = 979 #12
#    db = 6
#    ##################################################################
#    #                          CASE 03
#    #   GET /databases/entities/relations/:id with wrong entity
#    ##################################################################
#    json = "Entity[#{entity}] does not exists"
#    get :show, {:format => 'json', :database_id => db, :entity_id => entity, :id => relation}, { 'user' => user}
#    assert_response 400
#    assert_equal json, @response.body
#    
#    relation = 7
#    entity = 12
#    db = 987 #6
#    ##################################################################
#    #                          CASE 04
#    #   GET /databases/entities/relations/:id with wrong entity
#    ##################################################################
#    json = "Database[#{db}] does not exists"
#    get :show, {:format => 'json', :database_id => db, :entity_id => entity, :id => relation}, { 'user' => user}
#    assert_response 400
#    assert_equal json, @response.body
#    
#    relation = 7
#    entity = 52 #12
#    db = 6
#    ##################################################################
#    #                          CASE 05
#    #   GET /databases/entities/relations/:id with unrelated entity and relation
#    ##################################################################
#    json = "Relation[#{relation}] does not belong to Entity[#{entity}]"
#    get :show, {:format => 'json', :database_id => db, :entity_id => entity, :id => relation}, { 'user' => user}
#    assert_response 400
#    assert_equal json, @response.body
#    
#    relation = 7
#    entity = 12
#    db = 8 #6
#    ##################################################################
#    #                          CASE 06
#    #   GET /databases/entities/relations/:id with unrelated entity and database
#    ##################################################################
#    json = "Entity[#{entity}] does not belongs to Database[#{db}]"
#    get :show, {:format => 'json', :database_id => db, :entity_id => entity, :id => relation}, { 'user' => user}
#    assert_response 400
#    assert_equal json, @response.body
#    
#  end
#  
  def test_post
    # CASE 01: POST /relations
    
    user = User.find @db1_admin_user_id
    
    relation = 7
    entity = 12
    db = 6
    
    child = 20
    parent = 21 
    child_to_parent = "child to parent"
    parent_to_child = "parent to child"
    parent_side = 1
    child_side = 2
    
    data = {
            :parent_id => parent,
            :child_id => child,
            :from_parent_to_child_name => parent_to_child,
            :from_child_to_parent_name => child_to_parent,
            :parent_side_type_id => parent_side,
            :child_side_type_id => child_side
          }
    
    pre_count = Relation.count
    ###############################################################
    #                      CASE 01
    #  POST /relations
    ###############################################################
    post :create, 
      {
        :format => 'json',
        :relation => data.to_json
          
        }, 
        { 'user' => user }
      
    post_count = Relation.count   
    #assert_equal '', @response.body
    assert_response 201
    assert_equal 1, post_count - pre_count
    
      
  end
  
  
  def test_post_with_entity
    # CASE 01: POST /entities/relations
    # CASE 02: POST /entities/relations with wrong entity
    # CASE 03: POST /entities/relations?child=id all ok
    # CASE 04: POST /entities/relations?child=id child wrong
    # CASE 05: POST /entities/relations?child=id entity wrong
    # CASE 06: POST /entities/relations?parent=id all ok
    # CASE 07: POST /entities/relations?parent=id parent wrong
    # CASE 08: POST /entities/relations?parent=id entity wrong 
    
    
    
    user = User.find @db1_admin_user_id
    
    
    
    # This is the data to be sent as a relation
    child = 20
    parent = 21 
    child_to_parent = "child to parent"
    parent_to_child = "parent to child"
    parent_side = 1
    child_side = 2
    
    data = 
          {
            :parent_id => parent,
            :child_id => child,
            :from_parent_to_child_name => parent_to_child,
            :from_child_to_parent_name => child_to_parent,
            :parent_side_type_id => parent_side,
            :child_side_type_id => child_side
          }
    
    relation = 7
    entity = 12
    db = 6
    
    ###############################################################
    #                      CASE 01
    #  POST entities/relations
    ###############################################################
    post :create, 
      {
        :format => 'json',
        :entity_id => entity,
        :relation => data.to_json
        }, 
        { 'user' => user }
      
       
    assert_response 201
    
    
     # This is the data to be sent as a relation
    child = 20
    parent = 21 
    child_to_parent = "child to parent"
    parent_to_child = "parent to child"
    parent_side = 1
    child_side = 2
    
    data = 
          {
            :parent_id => parent,
            :child_id => child,
            :from_parent_to_child_name => parent_to_child,
            :from_child_to_parent_name => child_to_parent,
            :parent_side_type_id => parent_side,
            :child_side_type_id => child_side
          }
    
    relation = 7
    entity = 878 #12
    db = 6
    ###############################################################
    #                      CASE 02
    #  POST /relations with wrong entity
    ###############################################################
    post :create, 
      {
        :format => 'json',
        :entity_id => entity, 
        :relation => data.to_json
        }, 
        { 'user' => user }
      
     json = {:errors => ["Entity[#{entity}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body
    
    
    # This is the data to be sent as a relation
    child = 20
    parent = 21 
    child_to_parent = "child to parent"
    parent_to_child = "parent to child"
    parent_side = 1
    child_side = 2
    
    data = 
          {
            :parent_id => parent,
            :child_id => child,
            :from_parent_to_child_name => parent_to_child,
            :from_child_to_parent_name => child_to_parent,
            :parent_side_type_id => parent_side,
            :child_side_type_id => child_side
          }
    
    relation = 7
    entity = parent #12
    db = 6
    ###############################################################
    #                      CASE 03
    #  POST entities/relations?child with all correct
    ###############################################################
    post :create, 
      {
        :format => 'json',
        :entity_id => entity, 
        :child => child, 
        :relation => data.to_json
        }, 
        { 'user' => user }
      
     
    assert_response 201
    
    
    # This is the data to be sent as a relation
    child = 987 #20
    parent = 21 
    child_to_parent = "child to parent"
    parent_to_child = "parent to child"
    parent_side = 1
    child_side = 2
    
    data = 
          {
            :parent_id => parent,
            :child_id => child,
            :from_parent_to_child_name => parent_to_child,
            :from_child_to_parent_name => child_to_parent,
            :parent_side_type_id => parent_side,
            :child_side_type_id => child_side
          }
    
    relation = 7
    entity = parent #12
    db = 6
    ###############################################################
    #                      CASE 04
    #  POST entities/relations?child with wrong child
    ###############################################################
    post :create, 
      {
        :format => 'json',
        :entity_id => entity, 
        :child => child, 
        :relation => data.to_json
        }, 
        { 'user' => user }
      
    json = {:errors =>  [ "Entity[#{child}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body
    
    
    # This is the data to be sent as a relation
    child = 20
    parent = 21 
    child_to_parent = "child to parent"
    parent_to_child = "parent to child"
    parent_side = 1
    child_side = 2
    
    data = 
          {
            :parent_id => parent,
            :child_id => child,
            :from_parent_to_child_name => parent_to_child,
            :from_child_to_parent_name => child_to_parent,
            :parent_side_type_id => parent_side,
            :child_side_type_id => child_side
          }
    
    relation = 7
    entity = 979 #parent # 12
    db = 6
    ###############################################################
    #                      CASE 05
    #  POST entities/relations?child with correct child and wrong entity
    ###############################################################
    post :create, 
      {
        :format => 'json',
        :entity_id => entity, 
        :child => child, 
        :relation => data.to_json
        }, 
        { 'user' => user }
      
    json = {:errors => [ "Entity[#{entity}] does not exists" ]}.to_json
    assert_response 404
    assert_equal json, @response.body
    
    
    # This is the data to be sent as a relation
    child = 20
    parent = 21 
    child_to_parent = "child to parent"
    parent_to_child = "parent to child"
    parent_side = 1
    child_side = 2
    
    data = 
          {
            :parent_id => parent,
            :child_id => child,
            :from_parent_to_child_name => parent_to_child,
            :from_child_to_parent_name => child_to_parent,
            :parent_side_type_id => parent_side,
            :child_side_type_id => child_side
          }
    
    relation = 7
    entity = child #12
    db = 6
    ###############################################################
    #                      CASE 06
    #  POST entities/relations?parent with all correct
    ###############################################################
    post :create, 
      {
        :format => 'json',
        :entity_id => entity, 
        :parent => parent,
        :relation => data.to_json
        }, 
        { 'user' => user }
      
    
    assert_response 201
    
    # This is the data to be sent as a relation
    child = 20
    parent = 9879 #21 
    child_to_parent = "child to parent"
    parent_to_child = "parent to child"
    parent_side = 1
    child_side = 2
    
    data = 
          {
            :parent_id => parent,
            :child_id => child,
            :from_parent_to_child_name => parent_to_child,
            :from_child_to_parent_name => child_to_parent,
            :parent_side_type_id => parent_side,
            :child_side_type_id => child_side
          }
    
    relation = 7
    entity = child #12
    db = 6
    ###############################################################
    #                      CASE 07
    #  POST entities/relations?parent with wrong parent
    ###############################################################
    post :create, 
      {
        :format => 'json',
        :entity_id => entity, 
        :parent => parent,
        :relation => data.to_json
        }, 
        { 'user' => user }
      
    
    json = {:errors =>  [ "Entity[#{parent}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body
    
    # This is the data to be sent as a relation
    child = 20
    parent = 21 
    child_to_parent = "child to parent"
    parent_to_child = "parent to child"
    parent_side = 1
    child_side = 2
    
    data = 
          {
            :parent_id => parent,
            :child_id => child,
            :from_parent_to_child_name => parent_to_child,
            :from_child_to_parent_name => child_to_parent,
            :parent_side_type_id => parent_side,
            :child_side_type_id => child_side
          }
    
    relation = 7
    entity = 9879 #child # 12
    db = 6
    
    ###############################################################
    #                      CASE 08
    #  POST entities/relations?parent with correct parent and wrong entity
    ###############################################################
    post :create, 
      {
        :format => 'json',
        :entity_id => entity, 
        :parent => parent,
        :relation => data.to_json
        }, 
        { 'user' => user }
      
    
    json = {:errors =>  [ "Entity[#{entity}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body
    
  end
  
# *WARNING* POST /databases/entities/relations is NOT ALLOWED!
#  def test_post_with_database_entity
#    # CASE 01: POST /databases/entities/relations
#    # CASE 02: POST /databases/entities/relations with wrong entity
#    # CASE 03: POST /databases/entities/relations?child=id all ok
#    # CASE 04: POST /databases/entities/relations?child=id child wrong
#    # CASE 05: POST /databases/entities/relations?child=id entity wrong
#    # CASE 06: POST /databases/entities/relations?parent=id all ok
#    # CASE 07: POST /databases/entities/relations?parent=id parent wrong
#    # CASE 08: POST /databases/entities/relations?parent=id entity wrong 
#    # CASE 09: POST /databases/entities/relations?parent=id entity wrong 
#    
#    
#    
#    user = User.find @db1_admin_user_id
#    
#    
#    
#    # This is the data to be sent as a relation
#    child = 20
#    parent = 21 
#    child_to_parent = "child to parent"
#    parent_to_child = "parent to child"
#    parent_side = 1
#    child_side = 2
#    
#    relation = 7
#    entity = 12
#    db = 6
#    ###############################################################
#    #                      CASE 01
#    #  POST entities/relations
#    ###############################################################
#    post :create, 
#      {
#        :format => 'json',
#        :database_id => db,
#        :entity_id => entity,
#        :relation => 
#          {
#            :parent_id => parent,
#            :child_id => child,
#            :from_parent_to_child_name => parent_to_child,
#            :from_child_to_parent_name => child_to_parent,
#            :parent_side_type_id => parent_side,
#            :child_side_type_id => child_side
#          }
#        }, 
#        { 'user' => user }
#      
#       
#    assert_response :success    
#    
#    
#     # This is the data to be sent as a relation
#    child = 20
#    parent = 21 
#    child_to_parent = "child to parent"
#    parent_to_child = "parent to child"
#    parent_side = 1
#    child_side = 2
#    
#    relation = 7
#    entity = 878 #12
#    db = 6
#    ###############################################################
#    #                      CASE 02
#    #  POST /relations with wrong entity
#    ###############################################################
#    post :create, 
#      {
#        :format => 'json',
#        :database_id => db,
#        :entity_id => entity, 
#        :relation => 
#          {
#            :parent_id => parent,
#            :child_id => child,
#            :from_parent_to_child_name => parent_to_child,
#            :from_child_to_parent_name => child_to_parent,
#            :parent_side_type_id => parent_side,
#            :child_side_type_id => child_side
#          }
#        }, 
#        { 'user' => user }
#      
#     json = "Entity[#{entity}] does not exists"
#    assert_response 400
#    assert_equal json, @response.body
#    
#    
#    # This is the data to be sent as a relation
#    child = 20
#    parent = 21 
#    child_to_parent = "child to parent"
#    parent_to_child = "parent to child"
#    parent_side = 1
#    child_side = 2
#    
#    relation = 7
#    entity = parent #12
#    db = 6
#    ###############################################################
#    #                      CASE 03
#    #  POST entities/relations?child with all correct
#    ###############################################################
#    post :create, 
#      {
#        :format => 'json',
#        :database_id => db,
#        :entity_id => entity, 
#        :child => child, 
#        :relation => 
#          {
#            :parent_id => parent,
#            :child_id => child,
#            :from_parent_to_child_name => parent_to_child,
#            :from_child_to_parent_name => child_to_parent,
#            :parent_side_type_id => parent_side,
#            :child_side_type_id => child_side
#          }
#        }, 
#        { 'user' => user }
#      
#     
#    assert_response :success
#    
#    
#    # This is the data to be sent as a relation
#    child = 987 #20
#    parent = 21 
#    child_to_parent = "child to parent"
#    parent_to_child = "parent to child"
#    parent_side = 1
#    child_side = 2
#    
#    relation = 7
#    entity = parent #12
#    db = 6
#    ###############################################################
#    #                      CASE 04
#    #  POST entities/relations?child with wrong child
#    ###############################################################
#    post :create, 
#      {
#        :format => 'json',
#        :database_id => db,
#        :entity_id => entity, 
#        :child => child, 
#        :relation => 
#          {
#            :parent_id => parent,
#            :child_id => child,
#            :from_parent_to_child_name => parent_to_child,
#            :from_child_to_parent_name => child_to_parent,
#            :parent_side_type_id => parent_side,
#            :child_side_type_id => child_side
#          }
#        }, 
#        { 'user' => user }
#      
#    json = "Entity[#{child}] does not exists" 
#    assert_response 400
#    assert_equal json, @response.body
#    
#    
#    # This is the data to be sent as a relation
#    child = 20
#    parent = 21 
#    child_to_parent = "child to parent"
#    parent_to_child = "parent to child"
#    parent_side = 1
#    child_side = 2
#    
#    relation = 7
#    entity = 979 #parent # 12
#    db = 6
#    ###############################################################
#    #                      CASE 05
#    #  POST entities/relations?child with correct child and wrong entity
#    ###############################################################
#    post :create, 
#      {
#        :format => 'json',
#        :database_id => db,
#        :entity_id => entity, 
#        :child => child, 
#        :relation => 
#          {
#            :parent_id => parent,
#            :child_id => child,
#            :from_parent_to_child_name => parent_to_child,
#            :from_child_to_parent_name => child_to_parent,
#            :parent_side_type_id => parent_side,
#            :child_side_type_id => child_side
#          }
#        }, 
#        { 'user' => user }
#      
#    json = "Entity[#{entity}] does not exists" 
#    assert_response 400
#    assert_equal json, @response.body
#    
#    
#    # This is the data to be sent as a relation
#    child = 20
#    parent = 21 
#    child_to_parent = "child to parent"
#    parent_to_child = "parent to child"
#    parent_side = 1
#    child_side = 2
#    
#    relation = 7
#    entity = child #12
#    db = 6
#    ###############################################################
#    #                      CASE 06
#    #  POST entities/relations?parent with all correct
#    ###############################################################
#    post :create, 
#      {
#        :format => 'json',
#        :database_id => db,
#        :entity_id => entity, 
#        :parent => parent,
#        :relation => 
#          {
#            :parent_id => parent,
#            :child_id => child,
#            :from_parent_to_child_name => parent_to_child,
#            :from_child_to_parent_name => child_to_parent,
#            :parent_side_type_id => parent_side,
#            :child_side_type_id => child_side
#          }
#        }, 
#        { 'user' => user }
#      
#    
#    assert_response :success
#    
#    # This is the data to be sent as a relation
#    child = 20
#    parent = 9879 #21 
#    child_to_parent = "child to parent"
#    parent_to_child = "parent to child"
#    parent_side = 1
#    child_side = 2
#    
#    relation = 7
#    entity = child #12
#    db = 6
#    ###############################################################
#    #                      CASE 07
#    #  POST entities/relations?parent with wrong parent
#    ###############################################################
#    post :create, 
#      {
#        :format => 'json',
#        :database_id => db,
#        :entity_id => entity, 
#        :parent => parent,
#        :relation => 
#          {
#            :parent_id => parent,
#            :child_id => child,
#            :from_parent_to_child_name => parent_to_child,
#            :from_child_to_parent_name => child_to_parent,
#            :parent_side_type_id => parent_side,
#            :child_side_type_id => child_side
#          }
#        }, 
#        { 'user' => user }
#      
#    
#    json = "Entity[#{parent}] does not exists"
#    assert_response 400
#    assert_equal json, @response.body
#    
#    # This is the data to be sent as a relation
#    child = 20
#    parent = 21 
#    child_to_parent = "child to parent"
#    parent_to_child = "parent to child"
#    parent_side = 1
#    child_side = 2
#    
#    relation = 7
#    entity = 9879 #child # 12
#    db = 6
#    
#    ###############################################################
#    #                      CASE 08
#    #  POST entities/relations?parent with correct parent and wrong entity
#    ###############################################################
#    post :create, 
#      {
#        :format => 'json',
#        :database_id => db,
#        :entity_id => entity, 
#        :parent => parent,
#        :relation => 
#          {
#            :parent_id => parent,
#            :child_id => child,
#            :from_parent_to_child_name => parent_to_child,
#            :from_child_to_parent_name => child_to_parent,
#            :parent_side_type_id => parent_side,
#            :child_side_type_id => child_side
#          }
#        }, 
#        { 'user' => user }
#      
#    
#    json = "Entity[#{entity}] does not exists"
#    assert_response 400
#    assert_equal json, @response.body
#    
#  end
#  

  def test_put
    #  CASE 01: PUT /relations/:id with all ok
    #  CASE 02: PUT /relations/:id with wrong id
    #  CASE 03: PUT /relations/:id with resource missing
    
    user = User.find @db1_admin_user_id
    
    relation = 9
    resource = {}
    
    resource[:from_parent_to_child_name] = 'PARENT'
    resource[:from_child_to_parent_name] = 'CHILD'
    resource[:lock_version] = Relation.find(relation).lock_version.to_i
    ###################################################################
    #                            CASE 01
    #  PUT /relations/:id with all ok
    ###################################################################
    put :update, {:format => 'json', :id => relation, :relation => resource.to_json}, {'user' => user}
    assert_response :success
    json = @response.body

    json = JSON.parse(json)

    assert_equal json['from_parent_to_child_name'], 'PARENT'
    assert_equal json['from_child_to_parent_name'], 'CHILD'
    
    relation = 987987 #1000
    ###################################################################
    #                            CASE 02
    #  PUT /relations/:id with wrong id
    ###################################################################
    put :update, {:format => 'json', :id => relation, :relation => resource.to_json}, {'user' => user}
    assert_response 404
    json = {:errors => ["Relation[#{relation}] does not exists"]}.to_json
    assert_equal json, @response.body
    
    relation = 1000
    ###################################################################
    #                            CASE 03
    #  PUT /relations/:id with resource missing
    ###################################################################
    put :update, {:format => 'json', :id => relation}, {'user' => user}
    assert_response 400
    json = {:errors => ["Provide the relation resource to be created/updated"]}.to_json
    assert_equal json, @response.body
  end
  
  def test_without_login
    # FIXME: With be implemented after REST Auth
    assert true
#    id = 1
#    get :show, {:format => 'json', :id => id}, {'user' => nil}
#    assert_response 401
#    json = %Q~{"errors": ["Please login to consume the REST API"]}~
#    assert_equal json, @response.body  
  end
  
  def test_put_without_lock_version
    
    user = User.find(@db1_admin_user_id)
    
    relation = 30
    data = {'from_parent_to_child_name' => 'new_name'}
    #data[:lock_version] = 798
    
    put :update, {:format => 'json', :id => relation, 
                 :relation => data.to_json },
                 {'user' => user}
    
    json = {:errors => ["Provide lock_version for update/delete operations"]}.to_json    
    assert_response 400
    assert_equal json, @response.body, 'JSON NOT EQUAL!'
    
    
  end
  
  
  def test_put_with_entity
    #  CASE 01: PUT /entities/relations/:id with all ok
    #  CASE 02: PUT /entities/relations/:id with wrong id
    #  CASE 03: PUT /entities/relations/:id with wrong entity id
    #  CASE 04: PUT /entities/relations/:id where both unrelated
    #  CASE 05: PUT /entiies/relations/:id with resource missing
    
    user = User.find @db1_admin_user_id
    
    relation = 9
    entity = 11
    resource = {}
    
    resource[:from_parent_to_child_name] = 'PARENT'
    resource[:from_child_to_parent_name] = 'CHILD'
    resource[:lock_version] = Relation.find(relation).lock_version.to_i
    ###################################################################
    #                            CASE 01
    #  PUT /entities/relations/:id with all ok
    ###################################################################
    put :update, {:format => 'json', :entity_id => entity, :id => relation, :relation => resource.to_json}, {'user' => user}
    assert_response :success
    json = @response.body

    json = JSON.parse(json)

    assert_equal json['from_parent_to_child_name'], 'PARENT'
    assert_equal json['from_child_to_parent_name'], 'CHILD'
    
    relation = 987987 #1000
    entity = 30
    ###################################################################
    #                            CASE 02
    #  PUT /entities/relations/:id with wrong id
    ###################################################################
    put :update, {:format => 'json', :entity_id => entity, :id => relation, :relation => resource.to_json}, {'user' => user}
    assert_response 404
    json = {:errors => ["Relation[#{relation}] does not exists"]}.to_json
    assert_equal json, @response.body
    
    relation = 1000
    entity = 79797 #30
    ###################################################################
    #                            CASE 03
    #  PUT /entities/relations/:id with wrong entity
    ###################################################################
    put :update, {:format => 'json', :entity_id => entity, :id => relation, :relation => resource.to_json}, {'user' => user}
    assert_response 404
    json = {:errors => ["Entity[#{entity}] does not exists"]}.to_json
    assert_equal json, @response.body
    
    relation = 1000
    entity = 100 #30
    ###################################################################
    #                            CASE 04
    #  PUT /entities/relations/:id with both unrelated
    ###################################################################
    put :update, {:format => 'json', :entity_id => entity, :id => relation, :relation => resource.to_json}, {'user' => user}
    assert_response 400
    json = {:errors => ["Relation[#{relation}] does not belong to Entity[#{entity}]"]}.to_json
    assert_equal json, @response.body
    
    relation = 1000
    entity = 30
    ###################################################################
    #                            CASE 05
    #  PUT /relations/:id with resource missing
    ###################################################################
    put :update, {:format => 'json', :entity_id => entity, :id => relation}, {'user' => user}
    assert_response 400
    json = {:errors => ["Provide the relation resource to be created/updated"]}.to_json
    assert_equal json, @response.body
  end
  
    
  def test_get_and_put
    user = User.find_by_id @db1_admin_user_id
    
    id = 9
    res_name = 'relation'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    assert_response 200
    resource = JSON.parse(@response.body)
    
    
    resource['from_parent_to_child_name'] = 'GET AND PUT TEST'
    
    put :update, {:format => 'json', :id => id, res_name => resource.to_json}, {'user' => user}
    #assert_equal '', @response.body
    
    assert_response 200
    new_val = JSON.parse(@response.body)
    assert_equal resource['from_parent_to_child_name'], new_val['from_parent_to_child_name']    
    
  end
  
  def test_get_and_put_conflict
    user = User.find_by_id @db1_admin_user_id
    
    id = 9
    res_id = 78
    res_name = 'relation'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource = JSON.parse(@response.body)
    
    resource['from_parent_to_child_name'] = 'GET AND PUT TEST'
    resource['url'] = 'http://localhost:300/relations/' + res_id.to_s + '.json'
    
    json = {:errors => ["Requested ID is #{id} and ID in resource is #{res_id}. Are you dispatching your resource at the right location?"]}.to_json
    put :update, {:format => 'json', :id => id, res_name => resource.to_json}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
  end
  
  def test_get_and_put_version_conflict
    user = User.find_by_id @db1_admin_user_id
    
    id = 9
    res_name = 'relation'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    assert_response :success
    resource1 = JSON.parse(@response.body)
    
    resource1['from_parent_to_child_name'] = 'GET AND PUT TEST'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    assert_response :success
    resource2 = JSON.parse(@response.body)
    
    resource2['from_parent_to_child_name'] = 'GET AasddfasfND PUT TEST'
    
    put :update, {:format => 'json', :id => id, res_name => resource1.to_json}, {'user' => user}
    #assert_equal '', @response.body
    assert_response 200
    new_val = JSON.parse(@response.body)
    assert_equal resource1['name'], new_val['name']    
    
    msg = "Attempted to update a stale object"
    put :update, {:format => 'json', :id => id, res_name => resource2.to_json}, {'user' => user}
    assert_response 409

    assert_equal msg, JSON.parse(@response.body)['message']

    
    
    
    
  end
  \
  
  def test_delete
    # CASE 01: DELETE /relations/:id with all ok
    
    user = User.find @db1_admin_user_id
    
    #PENDING: The DELETE /relations is not allowed yet, because this might be
    # destructive without any checking whether the relation being deleted belongs to 
    # the user requesting the operation or not. When the REST call would include
    # the user authenticity information, then DELETE /relations would be possible. 
    #
    relation = 7
    entity = 12
    db = 6
    lock_version = Relation.find(relation).lock_version.to_i
    #################################################################
    #                            CASE 01
    #  DELETE /relations/:id with all ok                            
    #################################################################
    pre_count = Relation.count 
    delete :destroy, {:format => 'json', :lock_version => lock_version, :id => relation}, {'user' => user}
    json = {:errors =>  [ 'DELETE /relations call is not available for now. Call DELETE /entities/relations instead']}.to_json
    assert_response 400
    post_count = Relation.count
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    
  end
  
  def test_delete_with_version_conflict
    # Get a resource
    # Get its lock version
    # modify resource
    # post it back
    user = User.find_by_id @db1_admin_user_id
    
    id = 9
    entity = 11
    res_name = 'relation'
    lock_version = nil
    klass = Relation
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    #assert_equal '', @response.body
    assert_response 200
    resource = JSON.parse(@response.body)
    
    lock_version = resource['lock_version']
    
    # PUT it back
    put :update, {:format => 'json', res_name => resource.to_json, :id => id}, {'user' => user}
    
    msg = 'Attempted to delete a stale object'
    pre_count = klass.count
    delete :destroy, {:format => 'json', :entity_id => entity, :id => id, :lock_version => lock_version}, {'user' => user}
    post_count = klass.count
    assert_response 409
    assert_equal 0, post_count - pre_count

    assert_equal msg, JSON.parse(@response.body)['message']
    

  end
  
  def test_delete_with_entity_without_lock_version
    # CASE 01: DELETE /relations/:id with all ok
    
    user = User.find @db1_admin_user_id
    
    #PENDING: The DELETE /relations is not allowed yet, because this might be
    # destructive without any checking whether the relation being deleted belongs to 
    # the user requesting the operation or not. When the REST call would include
    # the user authenticity information, then DELETE /relations would be possible. 
    #
    relation = 7
    entity = 12
    db = 6
    lock_version = Relation.find(relation).lock_version.to_i
    #################################################################
    #                            CASE 01
    #  DELETE /relations/:id with all ok                            
    #################################################################
    pre_count = Relation.count 
    delete :destroy, {:format => 'json', :entity_id => entity,  :id => relation}, {'user' => user}
    json = {:errors =>  [ 'Provide lock_version for update/delete operations']}.to_json
    assert_response 400
    post_count = Relation.count
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body
    
  end
  
  
  def test_delete_with_entity
    # CASE 01: DELETE /entities/relations/:id all ok
    # CASE 02: DELETE /entities/relations/:id relation id wrong
    # CASE 03: DELETE /entities/relations/:id entity id wrong
    # CASE 04: DELETE /entities/relations/:id relation not belongs to entity
    
    user = User.find @db1_admin_user_id
    
    relation = 79897 # 7
    entity = 12
    db = 6
    lock_version = 797
    #################################################################
    #                            CASE 02
    #  DELETE entities/relations/:id with wrong relation
    #################################################################
    pre_count = Relation.count 
    delete :destroy, {:format => 'json',:lock_version => lock_version, :entity_id => entity, :id => relation}, {'user' => user}
    json = {:errors => [ "Relation[#{relation}] does not exists"]}.to_json
    assert_response 404
    post_count = Relation.count
    assert_equal(0, post_count - pre_count)
    assert_equal json, @response.body
    
    relation = 7
    entity = 987979 #12
    db = 6
    lock_version = Relation.find(relation).lock_version.to_i
    #################################################################
    #                            CASE 03
    #  DELETE entities/relations/:id with wrong entity
    #################################################################
    pre_count = Relation.count 
    delete :destroy, {:format => 'json', :lock_version => lock_version, :entity_id => entity, :id => relation}, {'user' => user}
    json = {:errors => [ "Entity[#{entity}] does not exists"]}.to_json
    assert_response 404
    post_count = Relation.count
    assert_equal(0, post_count - pre_count)
    assert_equal json, @response.body
    
    relation = 7
    entity = 30 #12
    db = 6
    lock_version = Relation.find(relation).lock_version.to_i
    #################################################################
    #                            CASE 04
    #  DELETE entities/relations/:id with relation not belonging to entity
    #################################################################
    pre_count = Relation.count 
    delete :destroy, {:format => 'json', :lock_version => lock_version, :entity_id => entity, :id => relation}, {'user' => user}
    json = { :errors => [ "Relation[#{relation}] does not belong to Entity[#{entity}]"]}.to_json
    assert_response 400
    post_count = Relation.count
    assert_equal(0, post_count - pre_count)
    assert_equal json, @response.body
    
    relation = 7
    entity = 12
    db = 6
    lock_version = Relation.find(relation).lock_version.to_i
    #################################################################
    #                            CASE 01
    #  DELETE entities/relations/:id with all ok                            
    #################################################################
    pre_count = Relation.count 
    delete :destroy, {:format => 'json',:lock_version => lock_version, :entity_id => entity, :id => relation}, {'user' => user}
    #json = 'DELETE /relations call is not available for now. Call DELETE /entities/relations instead'
    assert_response :success
    post_count = Relation.count
    assert_equal(-1, post_count - pre_count)
    
    
  end
  

end
  
  
