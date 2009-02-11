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
require 'rest/details_controller'
require 'entities2detail'

# assert_response status_code
# assert_redirect
# assert_redirect_to
# Re-raise errors caught by the controller.
class Rest::DatabasesController; def rescue_action(e) raise e end; end

#FIXME: These does not covers all the sitautions
class DetailsControllerTest < Test::Unit::TestCase
  
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
    @controller   = Rest::DetailsController.new
    @request      = ActionController::TestRequest.new
    @response      = ActionController::TestResponse.new
    
    @db1_admin_user_id = 2
    @db1_normal_user_id = 1000001
  end
  
  
  def test_without_login
    # will be rewritten after REST auth
    assert true
#    id = 63
#    get :show, {:format => 'json', :id => id}, {'user' => nil}
#    assert_response 401
#    json = %Q~{"errors": ["Please login to consume the REST API"]}~
#    assert_equal json, @response.body  
  end
  
  def test_accessing_irrelevant_item
    # CASE 01 First with only detail
    # CASE 02 Database and detail
    # CASE 03 Entity detail
    
    # CASE 01
    res_id = 1
    res_name = 'Detail'
    user = User.find @db1_admin_user_id
    json = {:errors =>["#{res_name}[#{res_id}] does not belong to User[#{user.id}] (\"#{user.login}\")"]}.to_json
    get :show, {:format => 'json', :id => res_id}, {'user' => user}
    assert_equal json, @response.body
    
    # CASE 02
    database = 3
    res_id = 1
    res_name = 'Database'
    user = User.find @db1_admin_user_id
    json = {:errors =>["#{res_name}[#{database}] does not belong to User[#{user.id}] (\"#{user.login}\")"]}.to_json
    get :show, {:format => 'json', :database_id => database, :id => res_id}, {'user' => user}
    assert_equal json, @response.body
    
    # CASE 03
    entity = 9
    res_id = 38
    res_name = 'Entity'
    user = User.find @db1_admin_user_id
    json = {:errors =>["#{res_name}[#{entity}] does not belong to User[#{user.id}] (\"#{user.login}\")"]}.to_json
    get :show, {:format => 'json', :entity_id => entity, :id => res_id}, {'user' => user}
    assert_equal json, @response.body
  end
  
  def test_accessing_without_adminstrative_rights
    assert true
    #FIXME: This tests are skipped for now. Feature depends upon
    # REST Auth
#    user  = User.find @db1_normal_user_id
#    parent = :database_id
#    parent_id = 6
#    id = 55
#    
#    get :index, {:format => 'json', parent => parent_id}, {'user' => user}
#    assert_response 200
#    
#    get :show, {:format => 'json', :id => id}, {'user' => user}
#    assert_response 200
#    
#    resource_name = :detail
#    resource = %Q~{"name": "asf"}~
#    msg = {:errors => ['This REST call needs administrative rights']}
#    
#    post :create, {:format => 'json', resource_name => resource}, {'user' => user}
#    assert_response 403
#    assert_equal msg.to_json, @response.body
#    
#    put :update, {:format => 'json', resource_name => resource}, {'user' => user}
#    assert_response 403
#    assert_equal msg.to_json, @response.body
#    
#    delete :destroy, {:format => 'json', :id => 45}, {'user' => user}
#    assert_response 403
    
    
  end
  
  # *Description*
  #   This tests the following URLs:
  #   GET /databases
  #
  def test_get_all
    # CASE 01: GET /database_id/details
    # CASE 02: GET /details with database missing
    # CASE 03: GET /details?database with incorrect database
    # CASE 04: GET /databases/details with all correct
    # CASE 05: GET /databases/details with incorrect database
    # CASE 06: GET /entities/details with all correct
    # CASE 07: GET /entiteis/details/ with incorrect entity
    # CASE 08: GET /databases/entities/details with all correct
    # CASE 09  GET /databases/entities/details with incorrect entity
    # CASE 10: GET /databases/entities/details with incorrect database
    # CASE 11  GET /databases/entities/details with irrelevant entity and database
   
    user = User.find @db1_admin_user_id
    
    db = 6
    ######################################################################
    #                            CASE 01
    # GET /:database_id/details
    # Get all the details of a database
    #######################################################################
    get :index, {:format => 'json', :database_id => db}, {'user' => user}
    json = Detail.find(:all, :conditions => ["database_id=?", db], :order => "lower(name)")
    #assert_equal '', @response.body
    assert_response :success
    result = JSON.parse(@response.body)
    assert_equal json.length, result['resources'].length, 'JSON different'
    
    
    db = 6
    ######################################################################
    #                           CASE 02
    #  GET /details
    # We ommitt the database parameter
    #######################################################################
    get :index, {:format => 'json'}, {'user' => user}
    json = {:errors => ['GET /details is not allowed, use GET /details?database=id instead.']}.to_json
    assert_response 400
    assert_equal json, @response.body, 'JSON different'
    
    db = 115
    ######################################################################
    #                           CASE 03
    # GET /details
    # with wrong database parameter
    #######################################################################
    get :index, {:format => 'json', :database_id => db}, {'user' => user}
    json = {:errors => ["Database[#{db}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body, 'JSON different'
    
    db = 6
    ######################################################################
    #                           CASE 04
    # GET /databases/:database_id/details
    # Get all the details of a database with correct database_id
    #######################################################################
    get :index, {:format => 'json', :database_id => db}, {'user' => user}
    json = Detail.find(:all, :conditions => ["database_id=?", db], :order => "lower(name)")
    assert_response :success
    result = JSON.parse(@response.body)
    assert_equal json.length, result['resources'].length, 'JSON different'
    
    
    db = 115
    ######################################################################
    #                          CASE 05                   
    # GET /databases/:database_id/details
    # Get all the details of a database with incorrect database_id
    #######################################################################
    get :index, {:format => 'json', :database_id => db}, {'user' => user}
    json = {:errors => ["Database[#{db}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body, 'JSON different'
    
    db = 8
    entity = 52
    ######################################################################
    #                          CASE 06                   
    # GET /entities/:entity_id/details
    # Get all the details of a an entitty with all correct
    #######################################################################
    get :index, {:format => 'json', :entity_id => entity}, {'user' => user}
    entity = Entity.find(entity, :include=> :entity_details)
      
      details = []
      entity.entity_details.each do |entity_detail|
        details.push(Detail.find(entity_detail.detail_id.to_i))
      end
    json = details #.to_json(:format => 'json')
    assert_response 200
    result = JSON.parse(@response.body)
    assert_equal json.length, result['resources'].length, 'JSON different'

    
    db = 8
    entity = 5211
    ######################################################################
    #                          CASE 07                   
    # GET /entities/:entity_id/details
    # Get all the details of a an entitty with incorrect entity
    #######################################################################
    get :index, {:format => 'json', :entity_id => entity}, {'user' => user}
    
    json = {:errors => ["Entity[#{entity}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body, 'JSON different'
    
    db = 8
    entity = 52
    ######################################################################
    #                          CASE 08
    # GET databases/:database_id/entities/:entity_id/details
    # Get all the details of a an entitty with all correct
    #######################################################################
    get :index, {:format => 'json', :database_id => db, :entity_id => entity}, {'user' => user}
    
    details = Detail.find(:all, :conditions => ["database_id=?",db], :order => "lower(name)")
    details.collect! { |detail| detail if detail.entities.collect{ |entity2detail| entity2detail.entity_id.to_i}.include?(entity.to_i) }
    json = details #.to_json(:format => 'json')
    assert_response 200
    result = JSON.parse(@response.body)
    assert_equal json.length, result['resources'].length, 'JSON different'
    
    
    db = 8
    entity = 1152
    ######################################################################
    #                          CASE 09
    # GET databases/:database_id/entities/:entity_id/details
    # Get all the details of a an entitty with incorrect entity id
    #######################################################################
    get :index, {:format => 'json', :database_id => db, :entity_id => entity}, {'user' => user}
    
    json = {:errors => ["Entity[#{entity}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body, 'JSON different'
    
    db = 118
    entity = 52
    ######################################################################
    #                          CASE 10
    # GET databases/:database_id/entities/:entity_id/details
    # Get all the details of a an entitty with incorrect database id
    #######################################################################
    get :index, {:format => 'json', :database_id => db, :entity_id => entity}, {'user' => user}
    
    
    json = {:errors => ["Database[#{db}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body, 'JSON different'
    
    db = 8
    entity = 13
    ######################################################################
    #                          CASE 11
    # GET databases/:database_id/entities/:entity_id/details
    # Get all the details of a an entitty with irrelevant database and entity
    #######################################################################
    get :index, {:format => 'json', :database_id => db, :entity_id => entity}, {'user' => user}
    
    json = {:errors => ["Entity[#{entity}] does not belongs to Database[#{db}]"]}.to_json
    assert_response 400
    assert_equal json, @response.body, 'JSON different'
    
    
    
  end
  
  def test_get_all_with_pagination
    # CASE 01: Mention of start_index and max_results
    # CASE 02: Mention of Order by with direction
    # CASE 03: Mention of Order by without direction
    # CASE 04: Mention a condition also
    # CASE 05: Getting only details of an entity
    
    user = User.find_by_id(@db1_admin_user_id)
    
    parent_resource = :database_id
    parent_id = 6
    start_index = 10
    max_results = 10
    order_by = 'name'
    direction = 'DESC'
    table_name = 'details'
    conditions = 'database_id=6'
    total_records = Detail.count_by_sql "SELECT COUNT(*) FROM  #{table_name} WHERE #{conditions}"
    conditions = 'id=50'
    
    
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

    assert_equal 10, result['resources'].length
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
    
    parent_resource = :entity_id
    parent_id = 100
    #########################################################
    #                        CASE 05
    #        Getting only details of an entity
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

    assert_equal 8, result['resources'].length
    assert_equal nil, result['direction']
    assert_equal nil.to_i, result['order_by'].to_i
    
    
  end
  
  def test_get_single
    # CASE 01: GET /details/:id
    # CASE 02: GET /details/:id wrong
    # CASE 03: GET /entities/details all correct
    # CASE 04: GET /entities/details detail wrong
    # CASE 05: GET /entities/details entity wrong
    # CASE 06: GET /entities/details entity detail irrelevant
    # CASE 07: GET /database/details all correct
    # CASE 08: GET /database/details detail wrong
    # CASE 09: GET /database/details/ database wrong
    # CASE 10: GET /databases/details/ databae and detail irrelevant
    # CASE 11: GET /database/entities/details/ all ok
    # CASE 12: GET /database/entities/details/ detail wrong
    # CASE 13: GET /database/entities/details/ entity wrong
    # CASE 14: GET /database/entities/details/ database wrong
    # CASE 15: GET /databases/entities/details entity detail unrelated
    # CASE 16: GET /databases/entities/details database entity unrelate.
    
    user = User.find @db1_admin_user_id
    
    detail = 100
    entity = 52
    db = 8
    ####################################################################
    #                          CASE 01
    # GET /detail/:id
    # with all correct
    ####################################################################
    get :show, {:format => 'json', :id => detail}, {'user' => user}
    #json = Detail.find(detail).to_json(:format => 'json')
    
    assert_response :success
    #assert_equal json, @response.body, 'JSON Different!'
    JSON.parse(@response.body)
    
    detail = 119100
    entity = 52
    db = 8
    ####################################################################
    #                          CASE 02
    # GET /detail/:id
    # with with incorrect detail id
    ####################################################################
    get :show, {:format => 'json', :id => detail}, {'user' => user}
    json = {:errors => ["Detail[#{detail}] does not exists"]}.to_json
    
    assert_response 404
    assert_equal json, @response.body, 'JSON Different!'
    
    detail = 100
    entity = 52
    db = 8
    ####################################################################
    #                          CASE 03
    # GET /entities/:entity_id/details/:id
    # with with all correct
    ####################################################################
    get :show, {:format => 'json', :entity_id => entity, :id => detail}, {'user' => user}
    json = @response.body #Detail.find(detail).to_json(:format => 'json')
    
    assert_response :success
    assert_equal json, @response.body, 'JSON Different!'
    JSON.parse(json)
    
    
    detail = 1157100
    entity = 52
    db = 8
    ####################################################################
    #                          CASE 04
    # GET /entities/:entityi_id/details/:id
    # with with incorrect detail
    ####################################################################
    get :show, {:format => 'json', :entity_id => entity, :id => detail}, {'user' => user}
    json = {:errors => ["Detail[#{detail}] does not exists"]}.to_json
    
    assert_response 404
    assert_equal json, @response.body, 'JSON Different!'
    
    detail = 100
    entity = 1952
    db = 8
    ####################################################################
    #                          CASE 05
    # GET /entities/:entityi_id/details/:id
    # with with incorrect entity
    ####################################################################
    get :show, {:format => 'json', :entity_id => entity, :id => detail}, {'user' => user}
    json = {:errors => ["Entity[#{entity}] does not exists"]}.to_json
    
    assert_response 404
    assert_equal json, @response.body, 'JSON Different!'
    
    detail = 75 #64
    entity = 52
    db = 8
    ####################################################################
    #                          CASE 06
    # GET /entities/:entityi_id/details/:id
    # with with unrelated entity and detail
    ####################################################################
    get :show, {:format => 'json', :entity_id => entity, :id => detail}, {'user' => user}
    json = {:errors => ["Detail[#{detail}] does not belong to Entity[#{entity}]"]}.to_json
    
    assert_response 400
    assert_equal json, @response.body, 'JSON Different!'
    
    detail = 100
    entity = 52
    db = 8
    ####################################################################
    #                          CASE 07
    # GET /databases/:database_id/details/:id
    # With all correct
    ####################################################################
    get :show, {:format => 'json', :database_id => db, :id => detail}, {'user' => user}
    json = @response.body# Detail.find(detail).to_json(:format => 'json')
    
    assert_response 200
    assert_equal json, @response.body, 'JSON Different!'
    JSON.parse(json)
    
    detail = 7100100
    entity = 52
    db = 8
    ####################################################################
    #                          CASE 08
    # GET /databases/:database_id/details/:id
    # With wrong detail id
    ####################################################################
    get :show, {:format => 'json', :database_id => db, :id => detail}, {'user' => user}
    json = {:errors => ["Detail[#{detail}] does not exists"]}.to_json
    
    assert_response 404
    assert_equal json, @response.body, 'JSON Different!'
    
    detail = 100
    entity = 52
    db = 810008
    ####################################################################
    #                          CASE 09
    # GET /databases/:database_id/details/:id
    # With wrong database id
    ####################################################################
    get :show, {:format => 'json', :database_id => db, :id => detail}, {'user' => user}
    json = {:errors => ["Database[#{db}] does not exists"]}.to_json
    
    assert_response 404
    assert_equal json, @response.body, 'JSON Different!'
    
    detail = 75 #43 # 100
    entity = 52
    db = 8
    ####################################################################
    #                          CASE 10
    # GET /databases/:database_id/details/:id
    # Where datbase and detail are not related.
    ####################################################################
    get :show, {:format => 'json', :database_id => db, :id => detail}, {'user' => user}
    json = {:errors => ["Detail[#{detail}] does not belong to Database[#{db}]"]}.to_json
    
    assert_response 400
    assert_equal json, @response.body, 'JSON Different!'
    
    detail = 100
    entity = 52
    db = 8
    ####################################################################
    #                          CASE 11
    # GET /databases/:database_id/entities/:entity_id/details/:id
    # With all ok
    ####################################################################
    get :show, {:format => 'json', :database_id => db, :entity_id => entity, :id => detail}, {'user' => user}
    json = @response.body # Detail.find(detail).to_json(:format => 'json')
    
    assert_response :success
    assert_equal json, @response.body, 'JSON Different!'
    JSON.parse(json)
    
    detail = 78747 #100
    entity = 52
    db = 8
    ####################################################################
    #                          CASE 12
    # GET /databases/:database_id/entities/:entity_id/details/:id
    # With wrong detail
    ####################################################################
    get :show, {:format => 'json', :database_id => db, :entity_id => entity, :id => detail}, {'user' => user}
    json = {:errors => ["Detail[#{detail}] does not exists"]}.to_json
    
    assert_response 404
    assert_equal json, @response.body, 'JSON Different!'
    
    detail = 100
    entity = 45788 #52
    db = 8
    ####################################################################
    #                          CASE 13
    # GET /databases/:database_id/entities/:entity_id/details/:id
    # With wrong entity
    ####################################################################
    get :show, {:format => 'json', :database_id => db, :entity_id => entity, :id => detail}, {'user' => user}
    json = {:errors => ["Entity[#{entity}] does not exists"]}.to_json
    
    assert_response 404
    assert_equal json, @response.body, 'JSON Different!'
    
    detail = 100
    entity = 52
    db = 78787 #8
    ####################################################################
    #                          CASE 14
    # GET /databases/:database_id/entities/:entity_id/details/:id
    # With wrong entity
    ####################################################################
    get :show, {:format => 'json', :database_id => db, :entity_id => entity, :id => detail}, {'user' => user}
    json = {:errors => ["Database[#{db}] does not exists"]}.to_json
    
    assert_response 404
    assert_equal json, @response.body, 'JSON Different!'
    
    detail = 75 #25 # 100
    entity = 52
    db = 8
    ####################################################################
    #                          CASE 15
    # GET /databases/:database_id/entities/:entity_id/details/:id
    # Where entity and detail are unrelated.
    ####################################################################
    get :show, {:format => 'json', :database_id => db, :entity_id => entity, :id => detail}, {'user' => user}
    json = {:errors => ["Detail[#{detail}] does not belong to Entity[#{entity}]"]}.to_json
    
    assert_response 400
    assert_equal json, @response.body, 'JSON Different!'
    
    detail = 100
    entity = 52
    db = 6 #8
    ####################################################################
    #                          CASE 16
    # GET /databases/:database_id/entities/:entity_id/details/:id
    # Where entity and database are irrelevant
    ####################################################################
    get :show, {:format => 'json', :database_id => db, :entity_id => entity, :id => detail}, {'user' => user}
    json = {:errors => ["Entity[#{entity}] does not belongs to Database[#{db}]"]}.to_json
    
    assert_response 400
    assert_equal json, @response.body, 'JSON Different!'
    
    
  end
  
  def test_linking
    # CASE 01: POST /entities/:entity_id/details?detail with all ok
    # CASE 02: POST /entities/:entity_id/details?detail  with wrong detail
    # CASE 03: POST /entities/:entity_id/details?detail with wrong entity
    
    
    user = User.find(@db1_admin_user_id)
    
    detail = 73
    entity = 52
    db = 8
    res = {}
    res[:detail_id] = detail
    
    #####################################################################
    #                              CASE 01
    #  POST /entities/details/:id
    #  with all correct
    #####################################################################
    pre_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    post :create, {:format => 'json', :entity_id => entity, :detail => res.to_json}, {'user' => user}
    post_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    assert_response 201
    assert_equal 1, post_count - pre_count
    #assert_equal 'asdf', @response.body
    
    
    detail = 731125 #73
    entity = 52
    db = 8
    res = {}
    res = {:detail_id => detail}
    #####################################################################
    #                              CASE 02
    #  POST /entities/details/:id
    #  with wrong detail
    #####################################################################
    pre_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    post :create, {:format => 'json', :entity_id => entity, :detail => res.to_json}, {'user' => user}
    post_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    json = {:errors => ["Detail[#{detail}] does not exists"]}.to_json
    #FIXME: This is changed from 404 to 400 due to valid_resource? functions.
    # This would be solved once we have our own exception class for deomenon.
    #assert_response 404
    #assert_equal 0, post_count - pre_count
    assert_equal json, @response.body, 'JSON Different!'
    
    detail = 73
    entity = 14555 #52
    db = 8
    res[:detail_id] = detail
    #####################################################################
    #                              CASE 03
    #  POST /entities/details/:id
    #  with wrong entity
    #####################################################################
    pre_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    post :create, {:format => 'json', :entity_id => entity, :detail => res.to_json}, {'user' => user}
    post_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    json = {:errors => ["Entity[#{entity}] does not exists"]}.to_json
    assert_response 404
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body, 'JSON Different!'
    
    
    
    
  end
  
#  def test_linking_with_database
#    # CASE 01: POST /databases/entities/details?detail with all ok
#    # CASE 02: POST /databases/entities/details?detail with detail wrong
#    # CASE 03: POST /databases/entities/details?detail with entity wrong
#    # CASE 04: POST /databases/entities/details?detial with database wrong
#    # CASE 05: POST /databases/entities/details?detail with entity and database irrelevant
#    user = User.find @db1_admin_user_id
#    
#    detail = 73:o
#    entity = 52
#    db = 8
#    res = {}
#    res[:detail_id] = detail
#    #####################################################################
#    #                              CASE 01
#    #  POST databases/:database_id/entities/details/:id
#    #  with all correct
#    #####################################################################
#    pre_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
#    post :create, {:format => 'json', :database_id => db, :entity_id => entity, :detail => res.to_json}, {'user' => user}
#    post_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
#    assert_response :success
#    assert_equal 1, post_count - pre_count
#    
#    detail = 979874 #73
#    entity = 52
#    db = 8
#    #####################################################################
#    #                              CASE 02
#    #  POST databases/:database_id/entities/details/:id
#    #  with wrond detail
#    #####################################################################
#    pre_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
#    post :create, {:format => 'json', :database_id => db, :entity_id => entity, :detail_id => detail}, {'user' => user}
#    post_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
#    json = {:errors => ["Detail[#{detail}] does not exists"]}.to_json
#    assert_response 404
#    assert_equal 0, post_count - pre_count
#    assert_equal json, @response.body, 'JSON Different!'
#    
#    
#    detail = 73
#    entity = 7848 #52
#    db = 8
#    #####################################################################
#    #                              CASE 03
#    #  POST databases/:database_id/entities/details/:id
#    #  with wrond entity
#    #####################################################################
#    pre_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
#    post :create, {:format => 'json', :database_id => db, :entity_id => entity, :detail_id => detail}, {'user' => user}
#    post_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
#    json = {:errors => ["Entity[#{entity}] does not exists"]}.to_json
#    assert_response 404
#    assert_equal 0, post_count - pre_count
#    assert_equal json, @response.body, 'JSON Different!'
#    
#    detail = 73
#    entity = 52
#    db = 78797 #8
#    #####################################################################
#    #                              CASE 04
#    #  POST databases/:database_id/entities/details/:id
#    #  with wrond database
#    #####################################################################
#    pre_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
#    post :create, {:format => 'json', :database_id => db, :entity_id => entity, :detail_id => detail}, {'user' => user}
#    post_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
#    json = {:errors => ["Database[#{db}] does not exists"]}.to_json
#    assert_response 404
#    assert_equal 0, post_count - pre_count
#    assert_equal json, @response.body, 'JSON Different!'
#    
#    detail = 73
#    entity = 52
#    db = 6 #8
#    #####################################################################
#    #                              CASE 04
#    #  POST databases/:database_id/entities/details/:id
#    #  with wrond database
#    #####################################################################
#    pre_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
#    post :create, {:format => 'json', :database_id => db, :entity_id => entity, :detail_id => detail}, {'user' => user}
#    post_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
#    json = {:errors => ["Entity[#{entity}] does not belongs to Database[#{db}]"]}.to_json
#    assert_response 400
#    assert_equal 0, post_count - pre_count
#    assert_equal json, @response.body, 'JSON Different!'
#    
#    
#  end
  
  def test_post
    # CASE 01: POST /databases/:database_id/database_id/details with all ok
    # CASE 02: POST /databases/:database_id/database_id/details with wrong database
    # CASE 03  POST /databases/:database_id/database_id/details with missing resource
    # CASE 04: POST /details with complete resource            
    # CASE 05: POST /details with incorrect detail[database_id]
    # CASE 06: POST /details with detail[database_id] missing
    
    
    user = User.find @db1_admin_user_id
    
    db = 8
    data = {:name => 'test_detailMohsin', :data_type_id => 1}
    ##################################################################
    #                         CASE 01
    #  POST /database_id/details with all ok
    ##################################################################
    pre_count = Detail.count
    post :create, 
      {:format =>'json', :database_id=> db,
        :detail=> data.to_json
      }, 
      {'user' => user}
    post_count = Detail.count
    assert_response 201
    assert_equal 1, post_count - pre_count, 'COUNT DIFFERS'
    #assert_equal '', @response.body
    
    
    
    db = 1234344 #8
    data = {:name => 'test_detailMohsin', :data_type_id => 1}
    ##################################################################
    #                         CASE 02
    #  POST /:database_id/details with wrong db
    ##################################################################
    pre_count = Detail.count
    post :create, 
      {:format =>'json', :database_id => db,
        :detail=> data.to_json
      }, 
      {'user' => user}
    post_count = Detail.count
    json = {:errors => ["Database[#{db}] does not exists"]}.to_json
#    assert_response 404
#    assert_equal 0, post_count - pre_count, 'COUNT DIFFERS'
    assert_equal json, @response.body
    
    db = 8
    data = {:name => 'test_detailMohsin', :data_type_id => 1}
    ##################################################################
    #                         CASE 03
    #  POST /:database_id/details without detail resource
    ##################################################################
    pre_count = Detail.count
    post :create, 
      {:format =>'json', :database_id => db
        #:detail=> data.to_json
      }, 
      {'user' => user}
    post_count = Detail.count
    json = {:errors => ['Provide the detail resource to be created/updated/linked']}.to_json
    assert_response 400
    assert_equal 0, post_count - pre_count, 'COUNT DIFFERS'
    assert_equal json, @response.body
    
    
    db = 8
    data = {:name => 'testcomplete_detailMohsin', :data_type_id => 1, :database_id => db}
    ##################################################################
    #                      CASE 04
    #  POST /details with complete resource            
    ##################################################################
    
    pre_count = Detail.count
    post :create, 
      {:format =>'json', 
        :detail=> data.to_json
      }, 
      {'user' => user}
    post_count = Detail.count
    assert_response 201
    assert_equal 1, post_count - pre_count, 'COUNT DIFFERS'
    #assert_equal '', @response.body
    
    db = 98797 #8
    data = {:name => 'testcomplete_detailMohsin', :data_type_id => 1, :database_id => db}
    ##################################################################
    #                      CASE 05
    #  POST /details with incorrect detail[database_id]
    ##################################################################
    json = {:errors => ["Database[#{db}] does not exists"]}.to_json
    pre_count = Detail.count
    post :create, 
      {:format =>'json', 
        :detail=> data.to_json
      }, 
      {'user' => user}
    post_count = Detail.count
    assert_response 404
    assert_equal 0, post_count - pre_count, 'COUNT DIFFERS'
    assert_equal json, @response.body
    
    db = 98797 #8
    data = {:name => 'testcomplete_detailMohsin', :data_type_id => 1}
    ##################################################################
    #                        CASE 06
    # CASE 05: POST /details with detail[database_id] missing
    ##################################################################
    json = {:errors => ['Provide database id as a nested REST call or mention it in detail resource']}.to_json
    pre_count = Detail.count
    post :create, 
      {:format =>'json', 
        :detail=> data.to_json
      }, 
      {'user' => user}
    post_count = Detail.count
    assert_response 400
    assert_equal 0, post_count - pre_count, 'COUNT DIFFERS'
    assert_equal json, @response.body
    
  end
  
  
  def test_put
    # CASE 01: PUT /details/:id with all ok
    # CASE 02: PUT /details/:id with wrong id
    
    user = User.find(@db1_admin_user_id)
    
    detail = 100
    entity = 52
    db = 8
    data = {:name => 'updated_detail_by_test'}
    data[:lock_version] = Detail.find(detail).lock_version
    ######################################################################
    #                        CASE 01
    #  PUT /details/:id with all ok
    ######################################################################
    put :update, 
      { :format => 'json', :id => detail,
        :detail => data.to_json
      },
      {'user' => user}
    
    model = Detail.find detail
    assert_response :success
    assert_similar model, @response.body

    
    detail = 32123 #100
    entity = 52
    db = 8
    data = {:name => 'updated_detail_by_test'}
    data[:lock_version] = 98798
    ######################################################################
    #                        CASE 02
    #  PUT /details/:id with wrong detail
    ######################################################################
    put :update, 
      { :format => 'json', :id => detail,
        :detail => data.to_json
      },
      {'user' => user}
   
    json = {:errors => ["Detail[#{detail}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body, 'JSON DIFFERS!'
    
    
  end
  
  def test_put_without_lock_version
    
    user = User.find(@db1_admin_user_id)
    
    detail = 73
    data = {'name' => 'new_name'}
    #data[:lock_version] = 798
    
    put :update, {:format => 'json', :id => detail,
                 :detail => data.to_json },
                 {'user' => user}
    
    json = {:errors => ["Provide lock_version for update/delete operations"]}.to_json    
    assert_response 400
    assert_equal json, @response.body, 'JSON NOT EQUAL!'
    
    
  end
  
  def test_put_with_entity
    # CASE 01: PUT /entities/details/:id with all ok
    # CASE 02: PUT /entities/details/:id with wrong detail
    # CASE 03: PUT /entities/details/:id with wrong entity
    # CASE 04: PUT /entities/details/:id with irrelevatn items
    
     user = User.find(@db1_admin_user_id)
    
    detail = 100
    entity = 52
    db = 8
    data = {:name => 'updated_detail_by_test'}
    data[:lock_version] = Detail.find(detail).lock_version
    ######################################################################
    #                        CASE 01
    #  PUT entities/details/:id with all ok
    ######################################################################
    put :update, 
      { :format => 'json', :entity_id => entity, :id => detail,
        :detail => data.to_json
      },
      {'user' => user}
    
    model = Detail.find(detail)
    assert_response :success
    assert_similar model, @response.body
    
    
    detail = 122312 #100
    entity = 52
    db = 8
    data = {:name => 'updated_detail_by_test'}
    data[:lock_version] = 987987
    ######################################################################
    #                        CASE 02
    #  PUT entities/details/:id with wrong detail
    ######################################################################
    put :update, 
      { :format => 'json', :entity_id => entity, :id => detail,
        :detail => data.to_json
      },
      {'user' => user}
    
    json = {:errors => ["Detail[#{detail}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body, 'JSON DIFFERS!'
    
    detail = 100
    entity = 65465 #52
    db = 8
    data = {:name => 'updated_detail_by_test'}
    data[:lock_version] = 7874
    ######################################################################
    #                        CASE 03
    #  PUT entities/details/:id with wrong entity
    ######################################################################
    put :update, 
      { :format => 'json', :entity_id => entity, :id => detail,
        :detail => data.to_json
      },
      {'user' => user}
    
    json = {:errors => ["Entity[#{entity}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body, 'JSON DIFFERS!'
    
    detail = 73 #100
    entity = 52
    db = 8
    data = {:name => 'updated_detail_by_test'}
    data[:lock_version] = 797
    ######################################################################
    #                        CASE 04
    #  PUT entities/details/:id with irrelevant detail and entity
    ######################################################################
    put :update, 
      { :format => 'json', :entity_id => entity, :id => detail,
        :detail => data.to_json
      },
      {'user' => user}
    
    json = {:errors => ["Detail[#{detail}] does not belong to Entity[#{entity}]"]}.to_json
    assert_response 400
    assert_equal json, @response.body, 'JSON DIFFERS!'
    
  end
  
  def test_put_with_database
    # CASE 01: PUT /databases/details/:id with all ok
    # CASE 02: PUT /databases/details/:id with wrong detail
    # CASE 03: PUT /databases/details/:id with wrong database
    # CASE 04: PUT /databases/details/:id where database and detail do not relate.
    
     user = User.find(@db1_admin_user_id)
    
    detail = 100
    entity = 52
    db = 8
    data = {:name => 'updated_detail_by_test'}
    data[:lock_version] = Detail.find(detail).lock_version
    ######################################################################
    #                        CASE 01
    #  PUT /databases/details/:id with all ok
    ######################################################################
    put :update, 
      { :format => 'json', :database_id => db, :id => detail,
        :detail => data.to_json
      },
      {'user' => user}
    
    #json = Detail.find(detail).to_json(:format => 'json')
    model = Detail.find(detail)
    assert_response :success
    assert_similar(model, @response.body)
    #assert_equal json, @response.body, 'JSON DIFFERS!'
    #JSON.parse(json)
    
    detail = 122312 #100
    entity = 52
    db = 8
    data = {:name => 'updated_detail_by_test'}
    data[:lock_version] = 797
    ######################################################################
    #                        CASE 02
    #  PUT /databases/details/:id with wrong detail
    ######################################################################
    put :update, 
      { :format => 'json', :database_id => db, :id => detail,
        :detail => data.to_json
      },
      {'user' => user}
    
    json = {:errors => ["Detail[#{detail}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body, 'JSON DIFFERS!'
    
    detail = 100
    entity = 52
    db = 457 #8
    data = {:name => 'updated_detail_by_test'}
    data[:lock_version] =979
    ######################################################################
    #                        CASE 03
    #  PUT /databases/details/:id with wrong database
    ######################################################################
    put :update, 
      { :format => 'json', :database_id => db, :id => detail,
        :detail => data.to_json
      },
      {'user' => user}
    
    json = {:errors => ["Database[#{db}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body, 'JSON DIFFERS!'
    
    detail = 100
    entity = 52
    db = 6 #8
    data = {:name => 'updated_detail_by_test'}
    data[:lock_version] = 797
    ######################################################################
    #                        CASE 04
    #  PUT /databases/entities/details/:id with irrelevant detail and database
    ######################################################################
    put :update, 
      { :format => 'json', :database_id => db, :id => detail,
        :detail => data.to_json
      },
      {'user' => user}
    
    json = {:errors => ["Detail[#{detail}] does not belong to Database[#{db}]"]}.to_json
    assert_response 400
    assert_equal json, @response.body, 'JSON DIFFERS!'
    
    
  end
  
  def test_put_with_database_entity
    # CASE 01: PUT /databases/entities/details/:id with all ok
    # CASE 02: PUT /databases/entities/details/:id with detail wrong
    # CASE 03: PUT /databases/entities/details/:id with entity wrong
    # CASE 04: PUT /databases/entities/details/:id with database wrong
    # CASE 05: PUT /databases/entities/details/:id with entity detail irrelevant
    # CASE 06: PUT /databases/entities/details/:id with unrelated entity and database
    
    user = User.find(@db1_admin_user_id)
    
    detail = 100
    entity = 52
    db = 8
    data = {:name => 'updated_detail_by_test'}
    data[:lock_version] = Detail.find(detail).lock_version
    ######################################################################
    #                        CASE 01
    #  PUT /databases/entities/details/:id with all ok
    ######################################################################
    put :update, 
      { :format => 'json', :database_id => db, :entity_id => entity, :id => detail,
        :detail => data.to_json
      },
      {'user' => user}
    
    model = Detail.find(detail)
    assert_response :success
    #assert_equal '', @response.body
    assert_similar(model, @response.body)
    
    
    detail = 545 #100
    entity = 52
    db = 8
    data = {:name => 'updated_detail_by_test'}
    data[:lock_version] = 797
    ######################################################################
    #                        CASE 02
    #  PUT /databases/entities/details/:id with wrong detail
    ######################################################################
    put :update, 
      { :format => 'json', :database_id => db, :entity_id => entity, :id => detail,
        :detail => data.to_json
      },
      {'user' => user}
    
    json = {:errors => ["Detail[#{detail}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body, 'JSON DIFFERS!'
    
    detail = 100
    entity = 98797 #52
    db = 8
    data = {:name => 'updated_detail_by_test'}
    data[:lock_version] = 8985
    ######################################################################
    #                        CASE 03
    #  PUT /databases/entities/details/:id with wrong entity
    ######################################################################
    put :update, 
      { :format => 'json', :database_id => db, :entity_id => entity, :id => detail,
        :detail => data.to_json
      },
      {'user' => user}
    
    json = {:errors => ["Entity[#{entity}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body, 'JSON DIFFERS!'
    
    detail = 100
    entity = 52
    db = 874 #8
    data = {:name => 'updated_detail_by_test'}
    data[:lock_version] = 748
    ######################################################################
    #                        CASE 04
    #  PUT /databases/entities/details/:id with wrong database
    ######################################################################
    put :update, 
      { :format => 'json', :database_id => db, :entity_id => entity, :id => detail,
        :detail => data.to_json
      },
      {'user' => user}
    
    json = {:errors => ["Database[#{db}] does not exists"]}.to_json
    assert_response 404
    assert_equal json, @response.body, 'JSON DIFFERS!'
    
    detail = 73 #100
    entity = 52
    db = 8
    data = {:name => 'updated_detail_by_test'}
    data[:lock_version] = 748
    ######################################################################
    #                        CASE 05
    #  PUT /databases/entities/details/:id with entity detail irrelevant
    ######################################################################
    put :update, 
      { :format => 'json', :database_id => db, :entity_id => entity, :id => detail,
        :detail => data.to_json
      },
      {'user' => user}
    
    json = {:errors => ["Detail[#{detail}] does not belong to Entity[#{entity}]"]}.to_json
    assert_response 400
    assert_equal json, @response.body, 'JSON DIFFERS!'
    
    detail = 100
    entity = 52
    db = 6 #8
    data = {:name => 'updated_detail_by_test'}
    data[:lock_version] = 748
    ######################################################################
    #                        CASE 06
    #  PUT /databases/entities/details/:id with entity database irrelevant
    ######################################################################
    put :update, 
      { :format => 'json', :database_id => db, :entity_id => entity, :id => detail,
        :detail => data.to_json
      },
      {'user' => user}
    
    json = {:errors => ["Entity[#{entity}] does not belongs to Database[#{db}]"]}.to_json
    assert_response 400
    assert_equal json, @response.body, 'JSON DIFFERS!'
    
  end
  
  def test_get_and_put
    user = User.find_by_id @db1_admin_user_id
    
    id = 100
    res_name = 'detail'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource = JSON.parse(@response.body)
    
    
    resource['name'] = 'GET AND PUT TEST'
    
    put :update, {:format => 'json', :id => id, res_name => resource.to_json}, {'user' => user}
    #assert_equal '', @response.body
    
    assert_response 200
    new_val = JSON.parse(@response.body)
    assert_equal resource['name'], new_val['name']    
    
  end
  
  def test_get_and_put_conflict
    user = User.find_by_id @db1_admin_user_id
    
    id = 100
    res_id = 78
    res_name = 'detail'
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource = JSON.parse(@response.body)
    
    resource['name'] = 'GET AND PUT TEST'
    resource['url'] = 'http://localhost:300/details/' + res_id.to_s + '.json'
    
    json = {:errors => ["Requested ID is #{id} and ID in resource is #{res_id}. Are you dispatching your resource at the right location?"]}.to_json
    put :update, {:format => 'json', :id => id, res_name => resource.to_json}, {'user' => user}
    assert_response 400
    assert_equal json, @response.body
  end
  
    def test_get_and_put_version_conflict
    user = User.find_by_id @db1_admin_user_id
    
    id = 80
    res_name = 'detail'
    
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
    #assert_equal resource1['name'], new_val['lock_version']    
    
    #get :show, {:format => 'json', :id => id}, {'user' => user}
    #resource3 = JSON.parse(@response.body)
    #assert_equal resource2['lock_version'], resource3['lock_version']
    #assert_equal '', resource3['lock_version']
    
    message = "Attempted to update a stale object"
    put :update, {:format => 'json', :id => id, res_name => resource2.to_json}, {'user' => user}
    assert_response 409

    json = JSON.parse(@response.body)['message']

    assert_equal message, json
    
    
    
    
  end
  
  
  
  def test_unlinking
    # CASE 01: DELETE /entities/:entity_id/details?detail with all ok
    # CASE 02: DELETE /entities/:entity_id/details?detail  with wrong detail
    # CASE 03: DELETE /entities/:entity_id/details?detail with wrong entity
    
    
    user = User.find(@db1_admin_user_id)
    
    detail = 100
    entity = 52
    db = 8
    #####################################################################
    #                              CASE 01
    #  DELETE /entities/details/:id
    #  with all correct
    #####################################################################
    pre_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    delete :destroy, {:format => 'json', :entity_id => entity, :id => detail}, {'user' => user}
    post_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    assert_response :success
    assert_equal 1, pre_count - post_count
    #assert_equal '', @response.body
    
    
    detail = 731125 #100
    entity = 52
    db = 8
    #####################################################################
    #                              CASE 02
    #  POST /entities/details/:id
    #  with wrong detail
    #####################################################################
    pre_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    delete :destroy, {:format => 'json', :entity_id => entity, :id => detail}, {'user' => user}
    post_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    json = {:errors => ["Detail[#{detail}] does not exists"]}.to_json
    assert_response 404
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body, 'JSON Different!'
    
    detail = 100
    entity = 14555 #52
    db = 8
    #####################################################################
    #                              CASE 03
    #  POST /entities/details/:id
    #  with wrong entity
    #####################################################################
    pre_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    delete :destroy, {:format => 'json', :entity_id => entity, :id => detail}, {'user' => user}
    post_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    json = {:errors => ["Entity[#{entity}] does not exists"]}.to_json
    assert_response 404
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body, 'JSON Different!'
    
  end
  
  def test_unlinking_with_database
    # CASE 01: DELETE /databases/entities/details/:id with all ok
    # CASE 02: DELETE /databases/entities/details/:id  with wrong detail
    # CASE 03: DELETE /databases/entities/details/:id with wrong entity
    # CASE 04: DELETE /databases/entities/details/:id with wrond database
    # CASE 05: DELETE /databases/entities/details/:id with irrelevant entity and detail
    # CASE 06: DELETE /databases/entities/details/:id with irrelevant entity and database
    
    
    
    user = User.find(@db1_admin_user_id)
    
    detail = 100
    entity = 52
    db = 8
    #####################################################################
    #                              CASE 01
    #  DELETE /entities/details/:id
    #  with all correct
    #####################################################################
    pre_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    delete :destroy, {:format => 'json', :database_id => db, :entity_id => entity, :id => detail}, {'user' => user}
    post_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    assert_response :success
    assert_equal 1, pre_count - post_count
    #assert_equal '', @response.body
    
    
    detail = 731125 #100
    entity = 52
    db = 8
    #####################################################################
    #                              CASE 02
    #  POST /entities/details/:id
    #  with wrong detail
    #####################################################################
    pre_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    delete :destroy, {:format => 'json', :database_id => db, :entity_id => entity, :id => detail}, {'user' => user}
    post_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    json = {:errors => ["Detail[#{detail}] does not exists"]}.to_json
    assert_response 404
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body, 'JSON Different!'
    
    detail = 100
    entity = 14555 #52
    db = 8
    #####################################################################
    #                              CASE 03
    #  POST /entities/details/:id
    #  with wrong entity
    #####################################################################
    pre_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    delete :destroy, {:format => 'json', :database_id => db, :entity_id => entity, :id => detail}, {'user' => user}
    post_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    json = {:errors => ["Entity[#{entity}] does not exists"]}.to_json
    assert_response 404
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body, 'JSON Different!'
    
    detail = 100
    entity = 52
    db = 678 #8
    #####################################################################
    #                              CASE 04
    #  POST /entities/details/:id
    #  with wrong database
    #####################################################################
    pre_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    delete :destroy, {:format => 'json', :database_id => db, :entity_id => entity, :id => detail}, {'user' => user}
    post_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    json = {:errors => ["Database[#{db}] does not exists"]}.to_json
    assert_response 404
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body, 'JSON Different!'
    
    detail = 73
    entity = 52
    db = 8
    #####################################################################
    #                              CASE 05
    #  POST /entities/details/:id
    #  with irrelevant entity and detail
    #####################################################################
    pre_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    delete :destroy, {:format => 'json', :database_id => db, :entity_id => entity, :id => detail}, {'user' => user}
    post_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    json = {:errors => ["Detail[#{detail}] does not belong to Entity[#{entity}]"]}.to_json
    
    assert_response 400
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body, 'JSON Different!'
    
    detail = 100
    entity = 52
    db = 6
    #####################################################################
    #                              CASE 06
    #  POST /entities/details/:id
    #  with irrelevant database and entity
    #####################################################################
    pre_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    delete :destroy, {:format => 'json', :database_id => db, :entity_id => entity, :id => detail}, {'user' => user}
    post_count = Entities2Detail.count(:conditions => ["entity_id=? and detail_id=?", entity, detail])
    json = {:errors => ["Entity[#{entity}] does not belongs to Database[#{db}]"]}.to_json
    
    assert_response 400
    assert_equal 0, post_count - pre_count
    assert_equal json, @response.body, 'JSON Different!'
     
  end
  
  def test_delete
    # CASE 01: DELETE /details/:id with all ok
    # CASE 02: DELETE /details/:id with wrong detail
    
    
    user = User.find @db1_admin_user_id
    
    detail = 73
    db = 8
    lock_version = Detail.find(detail).lock_version
    ##################################################################
    #                     CASE 01
    # CASE 01: DELETE /details/:id with all ok
    ##################################################################
    
    pre_count = Detail.count
    delete :destroy, {:format => 'json', :lock_version => lock_version, :id => detail}, {'user' => user}
    post_count = Detail.count
    #assert_equal '', @response.body
    assert_response :success
    assert_equal 1, pre_count-post_count, 'COUNT DIFFERS!'
    
    detail = 87877 #73
    db = 8
    lock_version = 7987
    ##################################################################
    #                     CASE 02
    # CASE 01: DELETE /details/:id with wrong detail
    ##################################################################
    
    pre_count = Detail.count
    delete :destroy, {:format => 'json', :lock_version => lock_version, :id => detail}, {'user' => user}
    post_count = Detail.count
    json = {:errors => ["Detail[#{detail}] does not exists"]}.to_json
    assert_response 404
    assert_equal 0, pre_count-post_count, 'COUNT DIFFERS!'
    assert_equal json, @response.body
    
    
    
  end
  
  def test_delete_with_version_conflict
    # Get a resource
    # Get its lock version
    # modify resource
    # post it back
    user = User.find_by_id @db1_admin_user_id
    
    id = 74
    res_name = 'detail'
    lock_version = nil
    klass = Detail
    
    get :show, {:format => 'json', :id => id}, {'user' => user}
    resource = JSON.parse(@response.body)
    
    lock_version = resource['lock_version']
    
    # PUT it back
    put :update, {:format => 'json', res_name => resource.to_json, :id => id}, {'user' => user}
    
    message = 'Attempted to delete a stale object'
    pre_count = klass.count
    delete :destroy, {:format => 'json', :id => id, :lock_version => lock_version}, {'user' => user}
    post_count = klass.count    
    assert_response 409

    json = JSON.parse(@response.body)['message']

    assert_equal 0, post_count - pre_count
    assert_equal message, json
  end
  
  def test_delete_with_database
    # CASE 01: DELETE /databases/:database_id/details/:id with all ok
    # CASE 02: DELETE /databases/:database_id/details/:id with wrong detail
    # CASE 03: DELETE /databases/:database_id/details/:id with wrong database
    
    
    user = User.find @db1_admin_user_id
    
    detail = 73
    db = 8
    lock_version = Detail.find(detail).lock_version
    ######################################################################
    #                             CASE 01
    # DELETE /databases/:database_id/details/:id with all ok
    ######################################################################
    pre_count = Detail.count
    delete :destroy, {:format => 'json', :lock_version => lock_version, :database_id => db, :id => detail}, {'user' => user}
    post_count = Detail.count
    assert_response :success
    assert_equal 1, pre_count-post_count
    
    detail = 456 #73
    db = 8
    lock_version = 78979
    ######################################################################
    #                             CASE 02
    # DELETE /databases/:database_id/details/:id with wrong detail
    ######################################################################
    pre_count = Detail.count
    delete :destroy, {:format => 'json', :lock_version => lock_version, :database_id => db, :id => detail}, {'user' => user}
    post_count = Detail.count
    json = {:errors => ["Detail[#{detail}] does not exists"]}.to_json
    assert_response 404
    assert_equal 0, pre_count-post_count
    assert_equal json, @response.body, 'JSON Differs!'
    
    detail = 73
    db = 879 #8
    lock_version = 797
    ######################################################################
    #                             CASE 03
    # DELETE /databases/:database_id/details/:id with wrong database
    ######################################################################
    pre_count = Detail.count
    delete :destroy, {:format => 'json', :lock_version => lock_version, :database_id => db, :id => detail}, {'user' => user}
    post_count = Detail.count
    json = {:errors => ["Database[#{db}] does not exists"]}.to_json
    assert_response 404
    assert_equal 0, pre_count-post_count
    assert_equal json, @response.body, 'JSON Differs!'
    
    
    
  end
  
  def test_delete_with_database_detail_irrelevant
    # CASE 01: DELETE /databases/:database_id/details/:id with irrelevant detail
    user = User.find @db1_admin_user_id
    
    detail = 73
    db = 6
    lock_version = Detail.find(detail).lock_version
    ######################################################################
    #                             CASE 01
    # DELETE /databases/:database_id/details/:id with all ok
    ######################################################################
    pre_count = Detail.count
    delete :destroy, {:format => 'json',:lock_version => lock_version,  :database_id => db, :id => detail}, {'user' => user}
    post_count = Detail.count
    json = {:errors => ["Detail[#{detail}] does not belong to Database[#{db}]"]}.to_json
    assert_response 400
    assert_equal 0, pre_count-post_count
    assert_equal json, @response.body, 'JSON DIFFERS'
  end
  
  def test_delete_without_version
    user = User.find(@db1_admin_user_id)
    
    entity = 14

    ######################################################################
    #                                                                    
    # DELETE /details/:id
    # with correct entity
    ######################################################################
    pre_count = Detail.count
    json = {:errors => ["Provide lock_version for update/delete operations"]}.to_json
    delete :destroy , {  :format => 'json',
                        #:lock_version => lock_version,
                        :id => entity
                    },
                    {'user' => user}
    
    
    post_count = Detail.count
    assert_response 400
    assert_equal json, @response.body
    assert_equal 0, pre_count - post_count, 'Detail count differs!'
  end
  
  
  
end
