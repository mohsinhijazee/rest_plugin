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
#################################################################################

#require 'activerecord'
module Rest::RestValidations
  
  
  def valid_account?(resource, params)
    case(params[:action])
    when 'create'
      raise BadResource.new, 'Account type is not mentioend in account resource' if !resource[:account_type_id]
      raise BadResource.new, 'Provide name' if !resource[:name]
      
      raise ResourceNotFound.new, 
        "AccountType[#{resource[:account_type_id]}] does not exists" if !AccountType.exists?(resource[:account_type_id])
      
    when 'update'
      raise BadResource.new, 'Provide lock_version for update/delete operations' if !resource[:lock_version]
    end
    
  end
  
  def valid_database?(resource, params)
    
    case(params[:action])
    when 'create'
      raise BadResource.new, "Name missing" if !resource[:name]
      # if the account id is not metnioned in the call or in the resource,
      # Then the account is assumed to be the user making the call.
      # Yes its a bit foolish why we need to do this, its for sure
      # that the user should only be allowed to create database in his
      # own account but for now, we let it go the way it is.
      resource[:account_id] = session['user'].account_id.to_i if !params[:account_id] and !resource[:account_id]
      raise BadResource.new, "POST databases should mention the account id in either database[account_id] or as nested REST call" if !resource[:account_id] and !params[:account_id]
      
      if resource[:account_id] and params[:account_id]
         if resource[:account_id].to_i != params[:account_id].to_i
           raise ConflictingCall.new, "Requested Account ID is #{params[:account_id]} and Account ID in resource is #{resource['account_id']}. Are you dispatching your resource at the right location?"
         end
      end
      
      resource[:account_id] = params[:account_id] if !resource[:account_id]
      
      if resource[:account_id]
        raise ResourceNotFound.new, "Account[#{resource[:account_id]}] does not exists" if !Account.exists? resource[:account_id]
      end
      
      
    when 'update'
      raise BadResource.new, "Provide lock_version for update/delete operations" if !resource[:lock_version]
    end
    
    belongs_to_user?(session['user'], :account => resource[:account_id]) if !resource.nil?
    
  end
  
  def valid_entity?(resource, params)
    case(params[:action])
    when 'create'
      raise BadResource.new, "Name missing" if !resource[:name]
      raise BadResource.new, "POST entities should mention the database id in either entity[database_id] or as nested REST call" if !resource[:database_id] and !params[:database_id]
      
      if resource[:database_id] and params[:database_id]
         if resource[:database_id].to_i != params[:database_id].to_i
           raise ConflictingCall.new, "Requested Database ID is #{params[:database_id]} and Database ID in resource is #{resource['database_id']}. Are you dispatching your resource at the right location?"
         end
      end
      
      resource[:database_id] = params[:database_id] if !resource[:database_id]
      
      if resource[:database_id]
        raise ResourceNotFound.new, "Database[#{resource[:database_id]}] does not exists" if !Database.exists? resource[:database_id]
      end
      
      
    when 'update'
      raise BadResource.new, "Provide lock_version for update/delete operations" if !resource[:lock_version]
      if resource[:database_id]
        raise ResourceNotFound.new, "Database[#{resource[:database_id]}] does not exists" if !Database.exists? resource[:database_id]
      end
    end
    
    belongs_to_user?(session['user'], :database => resource[:database_id]) if !resource.nil?
  end
  
  # FIXME: This does not validates in case of updates
  def valid_detail?(resource, params)
    
    
    type_of_call = :creation if params[:action] == 'create'
    type_of_call = :linkage if params[:entity_id] and params[:action] == 'create'
    type_of_call = :update if params[:action] == 'update'
    
    if type_of_call == :creation
      raise BadResource.new,"Name of detail missing" if !resource[:name]
      raise BadResource.new, "Datatype of detail missing" if !resource[:data_type_id]
      raise ResourceNotFound.new, "DataType[#{resource[:data_type_id]}] does not exists" if !DataType.exists?(resource[:data_type_id])
      
      # Check whether parent resourc provided?
      raise BadResource.new,"Provide database id as a nested REST call or mention it in detail resource" if !params[:database_id] and !resource[:database_id]
      
      if resource[:database_id] and params[:database_id]
        if resource[:database_id].to_i != params[:database_id].to_i
          raise ConflictingCall.new, "Requested Database ID is #{params[:database_id]} and Database ID in resource is #{resource['database_id']}. Are you dispatching your resource at the right location?"
        end
      end
      
      resource[:database_id] = params[:database_id] if !resource[:database_id]
      
      raise ResourceNotFound.new, "Database[#{resource[:database_id]}] does not exists"  if !Database.exists?(resource[:database_id])
    elsif type_of_call == :linkage
      raise BadResource.new, "Detail not provided to be linked in detail resource" if !resource[:detail_id]
      raise ResourceNotFound.new, "Detail[#{resource[:detail_id]}] does not exists" if !Detail.exists? resource[:detail_id]
      resource[:status_id] = 1 if !resource[:status_id]
      raise ResourceNotFound.new, "DetailStatus[#{resource[:status_id]}] does not exists"  if !DetailStatus.exists?(resource[:status_id])
      resource[:maximum_number_of_values] = 1 if !resource[:maximum_number_of_values]      
    elsif type_of_call  == :update
      raise BadResource.new, "Provide lock_version for update/delete operations" if !resource[:lock_version]
    end
    
    belongs_to_user?(session['user'], :database => resource[:database_id],
                                      :detail => resource[:detail_id]) if !resource.nil?
  end
  
  # Validates the propositions to be valid
  def valid_proposition?(resource, params)
    case(params[:action])
    when 'create'

      raise BadResource.new, 'Provide the detail id as detail_id in propositions resource or make a nested call' if !resource[:detail_id] and !params[:detail_id]
      
      if resource[:detail_id] and params[:detail_id]
        if resource[:detail_id].to_i != params[:detail_id].to_i
          raise ConflictingCall.new, "Requested Detail ID is #{params[:detail_id]} and Detail ID in resource is #{resource[:detail_id]}. Are you dispatching your resource at the right location?"
        end
      end
      
      resource[:detail_id] = params[:detail_id] if !resource[:detail_id]
      
      raise BadResource.new, "Provide values for proposition" if !resource[:value]
      resource[:value] = [resource[:value]] if !resource[:value].is_a? Array
      raise ResourceNotFound.new, "Detail[#{resource[:detail_id]}] does not exists" if !Detail.exists?(resource[:detail_id])
    when 'update'
      raise BadResource.new, 'Provide lock_version for update/delete operations' if !resource[:lock_version]
      raise BadResource.new, "Provide values for proposition" if !resource[:value]
      resource[:value] = resource[:value][0] if resource[:value].is_a? Array
    end
    
    belongs_to_user?(session['user'], :detail => resource[:detail_id]) if !resource.nil?
  end
  
    # *Description*
  #   Validates the instance resources that are provided in JSON fomrat.
  #   An exception is raised if no detail is mentioned in the instance.
  #   This method can be used to validate an instance for both, update and create
  #  *Arguments*
  #      +entity_id+: is the id of the entity
  #      +instance_resources+ is the instances in JSON format.
  #
  #  *Returns*
  #     Nothing
  def valid_instances?(resource, params)
    case(params[:action])
    when 'create'
      msg = "Provide the entity of the instance to be created either as a "
      msg += "field of the first instance to be created or make a nested call "
      msg += "POST /entities/:entity_id/instances"
      raise BadResource.new, msg  if !params[:entity_id] and !resource[0][:entity_id]
      
      if params[:entity_id] and resource[0][:entity_id]
        if params[:entity_id].to_i != resource[0][:entity_id].to_i
          raise BadResource.new, "Requested Entity ID is #{params[:entity_id]} and Entity ID in resource is #{resource[0]['entity_id']}. Are you dispatching your resource at the right location?"
        end
      end
      params[:entity_id] = resource[0][:entity_id] if !params[:entity_id]
      raise ResourceNotFound.new, "Entity[#{params[:entity_id]}] does not exists" if !Entity.exists?(params[:entity_id])
      
      resource.each do |instance|
        valid_instance?(instance, params)
      end
      
      belongs_to_user?(session['user'], :entity => resource[0][:entity_id]) if !resource.nil?
    when 'update'
      
      if !params[:entity_id]
        begin
          params[:entity_id] = Instance.find(params[:id]).entity_id
        rescue ActiveRecord::RecordNotFound => e
          raise ResourceNotFound.new, "Instance[#{params[:id]}] does not exists"
        end
      end
      
      # Check if the instance provided and entity relate to each other?
      if params[:entity_id] and params[:id]
        if !related_to_each_other?(:entity => params[:entity_id], :instance => params[:id])
          raise BadResource.new, "Instance[#{params[:id]}] does not belong to Entity[#{params[:entity_id]}]"
        end
      end
      
      valid_instance?(resource, params)
      
    end
  end
  
  # *Description*
  #   This function takes an entity id and an instancne defination in JSON format
  #   and then checks whether the JSON contains all the fields present in the
  #   entity or not.
  #   
  # *Arguments*
  #   +entity_id+: id of the entity
  #   +instance_resource+: singen instance in JSON format
  #   is different.
  # *Returns*
  #     Nothing
  def valid_instance?(instance, params)

    entity_id = params[:entity_id]
    bad_instance = true
    
    # Get the provided entity
    entity = Entity.find(entity_id)
    details = []
    entity.entity_details.each do |ed|
      # Pick the field name. If the name of the detail contains spaces,
      # we replace then with underscores because the consumer of the API is
      # supposed to replace the spaces with underscores in case the name of the fields
      # contains spaces.
      detail_name = ed.detail.name.gsub(' ', '_')
      details << detail_name
      # if we found even a single detail mentioned in the instance resource,
      # its not a bad instance then
      bad_instance = false if instance[detail_name]
    end
    
    raise BadResource.new, "Instance must mention at least one detail value to be created/updated" if bad_instance
    
    if params[:action] == 'update'
      raise BadResource.new, "Provide lock_version for update/delete operations" if !instance[:lock_version]
    end
    
    
    #FIXME: Should this code snipped be moved somewhere else?
    # For each provided field in the instance resource, remove that are not 
    # in the instance orginall
    keys = instance.keys
    
    # Delete all the details that do not belong todetails
    for field in keys  
      if instance[field].is_a? Array
        instance.delete field if not details.include? field
      end
    end
    

  end
  
  
  
  # Validates whether the provided detail is a valid resource or not
  def valid_detail_value?(resource, params)
    
    case(params[:action])
    when 'create'
      raise BadResource.new, "Provide values to be created in the resource" if !resource[:value]
      # if its not an array, convert it into an array
      resource[:value] = [resource[:value]] if !resource[:value].is_a? Array
    when 'update'
      # The values can be nil so that it acts as destroy but the key values must exist!
      raise BadResource.new, "Provide value to be updated in the resource" if !resource.has_key? 'value'
      #if its an array, pick only first value
      resource[:value] = resource[:value][0] if resource[:value].is_a? Array
      raise BadResource.new, "Provide lock_version for update/delete operations" if !resource[:lock_version] 
    end
    
    belongs_to_user?(session['user'], :instance => resource[:instance_id],
                                      :detail => resource[:detail_id]) if !resource.nil?
  end
  
  # Validates an incoming relation
  def valid_relation?(resource, params)
    case(params[:action])
    when 'create'
      if params[:entity_id]
        resource[:parent_id] = params[:entity_id] if !resource[:parent_id] and resource[:child_id]
        resource[:child_id] = params[:entity_id] if !resource[:child_id] and resource[:parent_id]
      end
      
      raise BadResource.new, "Provide parent_id for relation" if !resource[:parent_id]
      raise BadResource.new, "Provide child_id for relation" if !resource[:child_id]
      raise BadResource.new, "Provide parent_side_type_id for relation" if !resource[:parent_side_type_id]
      raise BadResource.new, "Provide child_side_type_id for relation" if !resource[:child_side_type_id]
      raise BadResource.new, "Provide from_parent_to_child_name for relation" if !resource[:from_parent_to_child_name]
      raise BadResource.new, "Provide from_child_to_parent_name for relation" if !resource[:from_child_to_parent_name]

      
      raise ResourceNotFound.new, 
            "Entity[#{resource[:parent_id]}] does not exists" if !Entity.exists?(resource[:parent_id])
         
      raise ResourceNotFound.new, 
            "Entity[#{resource[:child_id]}] does not exists" if !Entity.exists?(resource[:child_id])
          
      raise ResourceNotFound.new, 
            "RelationSideType[#{resource[:parent_side_type_id]}] does not exists" if !RelationSideType.exists?(resource[:parent_side_type_id])
          
      raise ResourceNotFound.new, 
            "RelationSideType[#{resource[:child_side_type_id]}] does not exists" if !RelationSideType.exists?(resource[:child_side_type_id])
      
          

      
    when 'update'
      raise BadResource.new, "Provide lock_version for update/delete operations" if !resource[:lock_version]
    end
    
    belongs_to_user?(session['user'], :entity => resource[:parent_id],
                                      :entity => resource[:child_id]) if !resource.nil?
  end
  
  def valid_link?(resource, params)
    case(params[:action])
    when 'create'
      if params[:instance_id]
        resource[:parent_id] = params[:instance_id] if !resource[:parent_id] and resource[:child_id]
        resource[:child_id] = params[:instance_id] if !resource[:child_id] and resource[:parent_id]
      end
      
      raise BadResource.new, "Provide parent_id" if !resource[:parent_id]
      raise BadResource.new, "Provide child_id" if !resource[:child_id]
      raise BadResource.new, "Provide relation_id" if !resource[:relation_id]
      
      raise ResourceNotFound.new,
        "Instance[#{resource[:parent_id]}] does not exists" if !Instance.exists?(resource[:parent_id])
      
      raise ResourceNotFound.new,
        "Instance[#{resource[:child_id]}] does not exists" if !Instance.exists?(resource[:child_id])
      
      raise ResourceNotFound.new,
        "Relation[#{resource[:relation_id]}] does not exists" if !Relation.exists?(resource[:relation_id])
      
    when 'update'
      raise BadResource.new, 'Update on links not allowed'
    end
    
    belongs_to_user?(session['user'], :instance => resource[:parent_id],
                                      :instance => resource[:child_id]) if !resource.nil?
  end
  
  def valid_user?(resource, params)
    case(params[:action])
    when 'create'
      # The user will have the same account as the one making the request.
      resource[:account_id] = session[:user].account_id.to_i if !params[:account_id] and !resource[:account_id]
      # Check whether parent resourc provided?
      raise BadResource.new,"Provide account id as a nested REST call or mention it in user resource" if !params[:account_id] and !resource[:account_id]
      
      if resource[:account_id] and params[:account_id]
        if resource[:account_id].to_i != params[:account_id].to_i
          raise ConflictingCall.new, "Requested Account ID is #{params[:account_id]} and Account ID in resource is #{resource['account_id']}. Are you dispatching your resource at the right location?"
        end
      end
      
      resource[:account_id] = params[:account_id] if !resource[:account_id]
      
      raise BadResource.new, 'Provide account_id'if !resource[:account_id]
      raise BadResource.new, 'Provide user_type_id'if !resource[:user_type_id]
      
      raise ResourceNotFound.new,
        "Account[#{resource[:account_id]}] does not exists" if !Account.exists? resource[:account_id]
      
      raise ResourceNotFound.new,
        "UserType[#{resource[:user_type_id]}] does not exists" if !AccountType.exists? resource[:user_type_id]
      
    when 'update'
      # commented out to disbale optimistic locking
      #raise BadResource.new, 'Provide lock_version for update/delete operations' if !resource[:lock_version]
    end
    
    belongs_to_user?(session['user'], :account => resource[:account_id]) if !resource.nil?
  end
  
  #  *Description*
  # The purpsoe of this function is to check whether the record for the
  # given model exists or not.
  # First argument is the model and second is the id of the record.
  # For example:
  #  exists?(Entity, 1)
  # would return true if the entity with id on exsits
  def exists?(klass, id)
    begin
      klass.find id
    rescue ActiveRecord::RecordNotFound => e
      return false
    end
    return true;
  end
  
  # *Description*
  #   Gets the error collection and creates an error message.
  #   {
  #     "errors": =>
  #                 [
  #                   "name: Name too short", 
  #                   "age: Negative not allowed"
  #                 ]
  #   }
  #
  def report_errors(model, exception = nil)
    
    error_msg = {}
    msgs = []
    #FIXME: Currently we assume that its allways a bad request (which is its 
    # mostly the reason for failure of an operation)
    error_code = 400
    
    #msgs << exception if exception.is_a? String
    
    if model
      # If model has errors, they will be returned
      if model.errors.length > 0
        error_code = 400
        model.errors.each do |field, reason|
          msgs << field.to_s + ': ' + reason.to_s
        end
      else
        msgs << exception.to_s if exception
      end
    else
      msgs << exception.to_s if exception
    end
    
    error_msg[:errors] = msgs
    
    return [error_msg.to_json, error_code]
  end
  
  # *Description*
  #   It checks if the id provided in the request and the id mentioned in the 
  #   resource are in conflict or not. If they are in conflict, then an error
  #   is raised.
  #
  def check_id_conflict(resource, id)
    # If id is not given, it means its not update
    # if resource not given, it means its not update
    # if resource does not contains id, its already safe
    return if !id
    return if !resource
    return if !resource['id']
    
    if resource['id'].to_i != id.to_i
      raise "Requested ID is #{id} and ID in resource is #{resource['id']}. Are you dispatching your resource at the right location?"
    end
    
  end
  
  
#h = 
#  [
#    {
#      'url'           => 'http://www.hotmail.com/databases/10.json',
#      'name'           => 'Projects',
#      'account_url'    => 'http://www.hotmail.com/accounts/1.json',
#      'entities_url'   => 'http://www.hotmail.com/entities.json',
#      'details_url'   => 'http://www.hotmail.com/details.json'
#
#    },
#    
#    {
#      'url'           => 'http://www.hotmail.com/databases/11.json',
#      'name'           => 'Songs',
#      'account_url'    => 'http://www.hotmail.com/accounts/1.json',
#      'entities_url'   => 'http://www.hotmail.com/entities.json',
#      'details_url'   => 'http://www.hotmail.com/details.json'
#    }
#  ]
#  
#i = \
#[
#  {
#    'Name' => [
#                {
#                  'url' => 'http://www.db.com/details/45.json', 
#                  'value' => 'Raph'
#                },
#                
#                {
#                  'url' => 'http://www.db.com/details/4.json', 
#                  'value' => 'Raphael'
#                },
#
#                {
#                  'url' => 'http://www.db.com/details/19.json', 
#                  'value' => 'raphinou'
#                }
#              ],
#              
#     'Age' => [45]
#  },
#  
#    {
#    'Name' => [
#                {
#                  'url' => 'http://www.db.com/details/95.json', 
#                  'value' => 'Mohsin'
#                },
#                
#                {
#                  'url' => 'http://www.db.com/details/97.json', 
#                  'value' => 'Shafeeque'
#                },
#
#                {
#                  'url' => 'http://www.db.com/details/123.json', 
#                  'value' => 'Hijazee'
#                }
#              ],
#              
#     'Age' => [22, 45, 67, {'link_url' => 'http://www.hotmail.com/1985.xml'}]
#  }
#  
#]


  def substitute_ids(json)
    
    json = substitute_ids_for_array(json) if json.is_a? Array
    json = substitute_ids_for_hash(json) if json.is_a? Hash
    return json
  end

  def substitute_ids_for_array(a)

  i = 0
  for i in 0...a.length
      if a[i].is_a? Array
       substitute_ids_for_array(a[i])
      end
      if a[i].is_a? Hash
       substitute_ids_for_hash(a[i])
      end
  end
  
  return a
end

  def substitute_ids_for_hash(h)
  #puts 'Came in hash()'
  keys = h.keys
  to_remove = []
  
  for key in keys

    if h[key].is_a? Array
        substitute_ids_for_array(h[key])
    elsif h[key].is_a? Hash
        substitute_ids_for_hash(h[key])
    else
        if key =~ /_?url$/
          id = nil
          # If _url field is not nil, extract integer
          id = h[key].gsub(/\.[a-zA-Z]+$/, '')[/[0-9]+$/] if h[key]
          if !id.nil?
            name = key.gsub(/url$/, 'id')
            h[name] = id.to_i
          end
          to_remove << key
        end
    end
#    end
  end
  
  to_remove.each {|key| h.delete key }
  return h
end

#  def print_fancy(data)
#  print_array(data) if data.is_a? Array
#  print_hash(data) if data.is_a? Hash
#end
#
#  def print_array(a)
#  puts '['
#  a.each do |item|
#  case(item.class.name)
#    when 'Array'
#      print_array(item)
#    when 'Hash'
#      print_hash(item)
#    else
#      puts item.to_s + ','
#  end
#  end
#  puts ']'  
#end
#
#  def print_hash(h)
#  puts '{'
#  h.each do |key, value|
#  case(value.class.name)
#    when 'Array'
#      puts "#{key} => "
#      print_array(value)
#    when 'Hash'
#      puts "#{key} => "
#      print_hash(value)
#    else
#      puts "#{key} => #{value},"
#  end
#  end
#  puts '}'
#end

  
 # *Description*
  #   This function checks whether the two items are related to each other or
  #   not. Provide the id of the two items and it will tell you whether they
  #   relate to each other or not.
  #   Following pairs are supported for now:
  #   account <=> database
  #   account <=> user
  #   entity <=> detail
  #   entity <=> database
  #   detail <=> database
  #   entity <=> relation
  #   instance   <=> link
  #   entity <=> instance
  #   detail <=> detail_value_proposition
  #   detail <=> value
  #   detail <=> instance
  #
  def related_to_each_other?(items={})
    
    
    
    if items[:account] and items[:user]
      return user_belongs_to_account?(items[:account], items[:user])
    end
    
    if items[:account] and items[:database]
      return database_belongs_to_account?(items[:account], items[:database])
    end
    
    if items[:entity] and items[:detail]
      return detail_belongs_to_entity?(items[:entity], items[:detail])
    end
    
    if items[:database] and items[:entity]
      return entity_belongs_to_database?(items[:database], items[:entity])
    end
    
    if items[:database] and items[:detail]
      return detail_belongs_to_database?(items[:database], items[:detail])
    end
    
    if items[:entity] and items[:relation]
      return relation_belongs_to_entity?(items[:entity], items[:relation])
    end
    
    if items[:instance] and items[:link]
      return link_belongs_to_instance?(items[:instance], items[:link])
    end
    
    if items[:detail] and items[:detail_value_proposition]
      return proposition_belongs_to_detail?(items[:detail], items[:detail_value_proposition])
    end
    
    if items[:entity] and items[:instance]
      return instance_belongs_to_entity?(items[:entity], items[:instance])
    end
    
    if items[:instance] and items[:detail] and items[:value]
      return value_belongs_to_detail_and_instance?(items[:instance], items[:detail], items[:value])
    end
    
    if items[:detail] and items[:value]
      return value_belongs_to_detail?(items[:detail], items[:value])
    end
    
    if items[:instance] and items[:detail]
      return detail_belongs_to_instance?(items[:instance], items[:detail])
    end
    
    #For all other, return false for now
    return false
  end
  
  
  # *Description*
  #   Checks whether the provided ids belong to the user or not
  #   Checks ownership of the following:
  #     * Account
  #     * User
  #     * Database
  #     * Entity
  #     * Detail
  #     * DetailValueProposition
  #     * Relation
  #     * Link
  #     * Instance
  #     * DetailValue
  #     
  #   *Arguments*
  #       * +user+ This can be user id as Fixnum or string or a user object
  #       * +items+ is a hash containing the ids of the items to be checked
  #       
  #   if you need to validate the ownership of a detail value, then you need to
  #   provide the detail id and value id in :detail and :value keys respectively
  #
  def belongs_to_user?(user, items={})
    
    raise "Rest::belongs_to_user?(): User not provided" if !user
    
    if user.is_a? String or user.is_a? Fixnum
      user = user.to_i
      user = User.find(user)
    end
    
    if items[:account]
      msg = "Account[#{items[:account]}] does not belong to User[#{user.id}] (\"#{user.login}\")"
      raise BadResource.new, msg  if user.account_id.to_i != Account.find(items[:account]).id.to_i
    end
    
    if items[:user]
      msg = "User[#{items[:user]}] does not belong to User[#{user.id}] (\"#{user.login}\")"
      raise BadResource.new, msg  if user.account_id.to_i != User.find(items[:user]).account_id.to_i
    end
    
    if items[:database]
      msg = "Database[#{items[:database]}] does not belong to User[#{user.id}] (\"#{user.login}\")"
      raise BadResource.new, msg  if user.account_id.to_i != Database.find(items[:database]).account_id.to_i
    end
    
    if items[:entity]
      msg = "Entity[#{items[:entity]}] does not belong to User[#{user.id}] (\"#{user.login}\")"
      raise BadResource.new, msg if user.account_id.to_i != Entity.find(items[:entity]).database.account_id.to_i
    end
    
    if items[:detail]
      msg = "Detail[#{items[:detail]}] does not belong to User[#{user.id}] (\"#{user.login}\")"
      raise BadResource.new, msg if user.account_id.to_i != Detail.find(items[:detail]).database.account_id.to_i
    end
    
    if items[:detail_value_proposition]
      msg = "DetailValueProposition[#{items[:detail_value_proposition]}] does not belong to User[#{user.id}] (\"#{user.login}\")"
      prop = DetailValueProposition.find(items[:detail_value_proposition])
      raise BadResource.new, msg if user.account_id.to_i != prop.detail.database.account_id.to_i
    end
    
    if items[:relation]
      msg = "Relation[#{items[:relation]}] does not belong to User[#{user.id}] (\"#{user.login}\")"
      raise BadResource.new, msg if user.account_id.to_i != Relation.find(items[:relation]).parent.database.account_id.to_i
      raise BadResource.new, msg if user.account_id.to_i != Relation.find(items[:relation]).child.database.account_id.to_i
    end
    
    if items[:link]
      msg = "Link[#{items[:link]}] does not belong to User[#{user.id}] (\"#{user.login}\")"
      raise BadResource.new if user.account_id.to_i != Link.find(items[:link]).parent.entity.database.account_id.to_i
      raise BadResource.new if user.account_id.to_i != Link.find(items[:link]).child.entity.database.account_id.to_i
      
    end
    
    if items[:instance]
      msg = "Instance[#{items[:instance]}] does not belong to User[#{user.id}] (\"#{user.login}\")"
      
      # This has to be changed due to Ticket#104
      entity = Entity.find(Instance.find(items[:instance].to_i).entity_id)
      
      #raise BadResource.new, msg if user.account_id.to_i != Instance.find(items[:instance]).entity.database.account_id.to_i
      raise BadResource.new, msg if user.account_id.to_i != entity.database.account_id.to_i
    end
    
    if items[:value]
      raise "Rest::belongs_to_user?(): Provide detail id for validation of ownership of a value" if !items[:detail]
      
      # Find the detail
      detail = Detail.find(items[:detail])
      
      case(detail.data_type.name)
       when 'madb_short_text',
            'madb_long_text',
            'madb_email',
            'madb_web_url',
            'madb_s3_attachment',
            'madb_file_attachment'
          value = DetailValue.find items[:value]
        when 'madb_date'
          value = DateDetailValue.find items[:value]
        when 'madb_integer'
          value = IntegerDetailValue.find items[:value]
        when 'madb_choose_in_list'
          value = DdlDetailValue.find items[:value]
        else
          raise "Rest::belongs_to_user?(): Detail Datatype no determined"
      end
      
      msg = "Value[#{items[:value]}] does not belong to User[#{user.id}] (\"#{user.login}\")"
      raise BadResource, msg if user.account_id.to_i != value.detail.database.account_id.to_i
    end
    
    # In all other cases, its OK
    return true
    
  end
  
  # *Description*
  # Checks whether the user belongs to the account or not.
  #
  def user_belongs_to_account?(account_id, user_id)
    return account_id.to_i == User.find(user_id).account_id.to_i
  end
  
  # *Description*
  #   Checks whether the given detail bleongs to the entity.
  #
  def detail_belongs_to_entity?(entity_id,detail_id)
    entity = Entity.find entity_id
    return entity.details.collect { |e2d| e2d.detail_id.to_i }.include?(detail_id.to_i)    
  end
  
  # *Description*
  #   Checks whether the given entity belongs to the given database.
  #
  def entity_belongs_to_database?(database_id, entity_id)
    entity = Entity.find entity_id
    puts "database_id = #{database_id} and entity_id = #{entity_id}"
    puts "entity.database.id.to_i = #{entity.database.id.to_i}"
    return entity.database.id.to_i == database_id.to_i
    
  end
  
  # *Description*
  #   Checks whether the given detial belongs the given detail
  def detail_belongs_to_database?(database_id, detail_id)
    detail = Detail.find detail_id
    return detail.database.id.to_i == database_id.to_i
  end
  
  def relation_belongs_to_entity?(entity_id, relation_id)    
    #entity = Entity.find entity_id
    relation = Relation.find relation_id
    
    if relation.parent_id.to_i == entity_id.to_i or 
       relation.child_id.to_i == entity_id.to_i
       return true
    end
    
    return false
  end
  
  def link_belongs_to_instance?(instance_id, link_id)
    link = Link.find(link_id)
    
    if link.parent_id.to_i == instance_id.to_i or
        link.child_id.to_i == instance_id.to_i
      return true
    end
    
    return false
    
  end
  
  def proposition_belongs_to_detail?(detail_id, prop_id)
    prop = DetailValueProposition.find(prop_id)
    return prop.detail_id.to_i == detail_id.to_i
  end
  
  def database_belongs_to_account?(account_id, database_id)
    return Database.find(database_id).account_id.to_i == account_id.to_i
  end
  
  def instance_belongs_to_entity?(entity_id, instance_id)
    return Instance.find(instance_id).entity_id.to_i == entity_id.to_i
  end
  
  def value_belongs_to_detail?(detail_id, value_id)
    detail = Detail.find detail_id
    
    value = nil
    case(detail.data_type.name)
    when  'madb_short_text',
          'madb_long_text',
          'madb_email',
          'madb_web_url'
          'madb_s3_attachment'
          value = DetailValue.find value_id
    when  'madb_date'
      value = DateDetailValue.find value_id
    when  'madb_integer'
      value = IntegerDetailValue.find value_id
    when 'madb_choose_in_list'
      value = DdlDetailValue.find value_id
    end
    
    return detail_id.to_i == value.detail_id.to_i
  end
  
  def detail_belongs_to_instance?(instance_id, detail_id)
    entity_id = Instance.find(instance_id).entity_id
    return detail_belongs_to_entity?(entity_id, detail_id)
  end
  
  def value_belongs_to_detail_and_instance?(instance_id, detail_id, value_id)
    detail = Detail.find detail_id
    
    value = nil
    case(detail.data_type.name)
    when  'madb_short_text',
          'madb_long_text',
          'madb_email',
          'madb_web_url',
          'madb_file_attachment'
          'madb_s3_attachment'
          value = DetailValue.find value_id
    when  'madb_date'
      value = DateDetailValue.find value_id
    when  'madb_integer'
      value = IntegerDetailValue.find value_id
    when 'madb_choose_in_list'
      value = DdlDetailValue.find value_id
    end
    
    return (value.detail_id.to_i == detail_id.to_i and value.instance_id.to_i == instance_id.to_i)
  end
  

      
end

# The version that explicitly replaces the parts of the resource
#  def substitute_ids(json)
#    
#    json = substitute_ids_for_array(json) if json.is_a? Array
#    json = substitute_ids_for_hash(json) if json.is_a? Hash
#    return json
#  end
#
#  def substitute_ids_for_array(a)
#
##  puts 'Came in array'
#  i = 0
#  for i in 0...a.length
#     #case(a[i].class.name)
##       when 'Array'
#      if a[i].is_a? Array
##       puts 'array(): Item is Array'
#       a[i] = substitute_ids_for_array(a[i])
#      end
##       when'Hash'
#      if a[i].is_a? Hash
##        puts 'array(): Item is Hash'
#       a[i] = substitute_ids_for_hash(a[i])
#      end
##     end
#  end
#  
#  return a
#end
#
#  def substitute_ids_for_hash(h)
#  puts 'Came in hash()'
#  keys = h.keys
#  to_remove = []
#  
#  for key in keys
##    case(h[key].class.name)
##      when 'Array'
#    if h[key].is_a? Array
##        puts 'hash(): Item is Array'
#        h[key] = substitute_ids_for_array(h[key])
#    elsif h[key].is_a? Hash
##      when 'Hash'
##        puts 'hash(): Item is Hash'
#        h[key] = substitute_ids_for_hash(h[key])
##      else
#    else
# #       puts 'hash(): Item is simple data'
#        if key =~ /_?url$/
#          id = nil
#          # If _url field is not nil, extract integer
#          id = h[key].gsub(/\.[a-zA-Z]+$/, '')[/[0-9]+$/] if h[key]
#          if !id.nil?
##            puts 'hash(): Item has _url'
#            name = key.gsub(/url$/, 'id')
##            puts "#{name} => #{id}"
#            h[name] = id.to_i
#            #to_remove << key
#          end
#          to_remove << key
#        end
#    end
##    end
#  end
#  
#  to_remove.each {|key| h.delete key }
#  return h
#end