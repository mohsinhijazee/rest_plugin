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

# *Description*
#   This module contains functions for getting a single instance or all instances
#   of an entity.The results are transformed to JSON.
#   
#   NOTE: All the methods with _ at the start are internla methods and should
#   not be called from outisid
#   *Roadmap*:
#     *Creating/updating instances
# FIXME: Dcoument all the arguments of this modlule
# FIXME: Should we replace all the parameters of ids with whole objects?
# FIXME: All the methods with _ are internal, make them private.module InstanceProcessor
# FIXME: Should use less error checking, instead rely on exceptions.
# FIXME: SaveValues function is not checking on the limit of allowed maximum number
# of values!
# FIXME: Check for all the places if they're raising proper exceptions
require 'exceptions.rb'

module InstanceProcessor
include Rest::UrlGenerator  

  # *Description*
  #   Validates the instance resources for the operation of updates.
  #   
  #  *Arguments*
  #      +entity_id+: is the id of the entity
  #      +instance_resources+ are instances from JSON
  #
  #  *Returns*
  #     bad details in an array or an array of zero length if all ok
  # NOTE: The ids of the values present in the instances are not validated
  # explicity and it is left for the fucntions to raise excetpinos that will be
  # caught by the users.
#  def valid_instances_for_update?(entity_id, instance_resources)
#    # Holds the bad details
#    bad_details = []
#    
#    # For each of the provided instances
#    instance_resources.each do |instance|
#      # Validate and get any bad details in it
#      bad_details = valid_instance_for_update?(entity_id, instance)
#      return bad_details if bad_details.lenght > 0
#    end
#    
#    return bad_details
#  end
#  

  # *Description*
  #   Checks whether the given instance resource is valid for updation or 
  #   not.
  #
  # *Arguments*
  #   +entity_id+ is the id of the entity.
  #   +instance_resource+ is a single instance
  #   
  # *Returns**
  #   An array of missing details.
  # 
  #
#  def valid_instance_for_update?(entity_id, instance_resource)
#    
#    # Get all the detials
#    detail_ids = get_detail_ids(entity_id)
#    
#    # This will hold the details that are not in the entity of the instance.
#    bad_details = []
#    
#    # Cycle through each of the detail provided in the instance resource and
#    # check whether it is in the entity for which the instance is to be updated or
#    # not
#    instance_resource.each_key do |detail|
#      # If the detail of the given name is not in the enitity
#      bad_details.push detail if !detail_ids[detail]
#    end
#    
#    return bad_details
#    
#  end
#  
  # *Description*
  #   Saves the instances provided to it in JSON format into the entity of the
  #   given id.
  #   
  # *Arguments*
  #   +entity_id+: id of the entity
  #   +instnace_resource+: Single instancce resource in JSON fomrat
  #   Returns an array containing the ids of the newly created instances
  def save_instances(entity_id, instance_resources)
    # This contains the instance ids of the newly created instances
    instances = []
    
    instance_resources.each do |instance_resource|
      instances << save_instance(entity_id, instance_resource)
    end
    return instances
  end
  
  # *Description*
  # Saves a single instance
  # Returns the newly created instance
  def save_instance(entity_id, instance_resource)
    
    
      instance = new_instance(entity_id)  
      detail_ids = get_detail_ids(entity_id)

      instance_resource.each do |detail_name, values|

        # If value is not an array, skip it
        next if !values.is_a?(Array)
        next if !detail_ids[detail_name]
        raise "InstanceProcessor#save_instance(): Detail #{detail_name} does not belong to Entity[#{entity_id}]!" if !detail_ids[detail_name]
        
        save_all_values(instance.id, detail_ids[detail_name], values)
      end
    
    
    return instance
     
  end
 
  # *Description*
  #  Creates a new instance for the given entity and returns it after saving
  def new_instance(entity_id)
    instance = Instance.new
    instance.entity_id = entity_id
    # save! method because an exception would be raised and wouuld be caught
    # at the upper levels.
    instance.save!
    return instance
  end
  
  
  # *Description*
  # Gets all the details of an entity in a hash which is like this:
  # detail_ids[:detail_name] = id of the detail
  # Like if there is a detail with name "Working Hours" then:
  # detail_ids['Working_Hours'] = 74
  def get_detail_ids(entity_id)
    detail_ids = {}
    entity = Entity.find entity_id
    
    entity.entity_details.each do |ed|
      detail_ids[ed.detail.name.gsub(' ', '_')] = ed.detail.id
    end
    return detail_ids
  end
  
  # *Description*
  #   Updates an instance of the given id.
  # Returns the updated instance
  def update_instance(instance_id, instance_resource)
    
    raise BadResource.new, "Provide lock_version for update/delete operations" if !instance_resource['lock_version']
    
    instance = Instance.find(instance_id)
    
    
    
    # Get the version from the instance resource and do a save early
    # so that if there is a conflict at the instance level, its caught early
    # or the instance version is incremented.
    # If further processing raises an expcetion, this version change
    # is automatically changed because call to this function would always be
    # in a transaction
    instance.lock_version = instance_resource['lock_version']
    instance.save!
    
    detail_ids = get_detail_ids(instance.entity_id)
#    puts "Came here"
    instance_resource.each do |detail, values|
      next if !values.is_a? Array
      # For each of the value provided
      values.each do |value|
        #puts "Saving or updating #{value}..."
        puts "Instance[#{instance_id}], detail = #{detail} detail_ids[#{detail} = #{detail_ids[detail]}"
        save_or_update_value(instance_id, detail_ids[detail], value)
      end
    end
    return instance
  end
  
  # *Description*
  #  Saves or updates  a value
  def save_or_update_value(instance_id, detail_id, value)
    if value['id']
      puts "Updating #{value['id']}"
      raise BadResource.new, "Provide lock_version for detail value #{value['id']}" if !value['lock_version']
      #return update_value(detail_id, value['id'], value['value'])
      return update_value(detail_id, value['id'], value)
    else
      puts "Saving #{value['value']}"
      return save_value(instance_id, detail_id, value['value'])
    end
  end
  

  
  # *Description*
  #   This function gets a single value given the id of the detail and id of the 
  #   value.
  #   
  # *Workflow*
  #   Detail of the given id is picked and its data type class is obtained
  #   throught the function +class_from_name+() and a find is executed on it
  #
  def get_single_value(detail_id, value_id)
    # Initially, we have no value
    value = nil
    
    # Find the detail
    detail = Detail.find(detail_id, :include => :data_type)
    
    # Get the data type of the detail and its handing data type class and
    # find the vlaue of given id through that.
    value = class_from_name(detail.data_type.class_name).find(value_id)
    
    return value
   
  end
  
  
  # *Description*
  # Saves all the details based on the data type of the detail.
  # The last argument is an array holding single or multiple values.
  #
  # *Workflow*
  #   The data type of the given detail is picked and then each of the value
  # in the array is saved thorugh the +save_value+() function
  
  def save_all_values(instance_id, detail_id, values)
    
    created_values = []
    # Begin a transaction
#    DetailValue.transaction do
      # Save each value
      values.each do |value|   
        created_values.push(save_value(instance_id, detail_id, value))
      end
#    end
    return created_values
  end
  
  # *Descritption*
  # Saves a single value based on the data type. 
  # 
  # *Workflow*
  #  A new class is created of the appropiate type based on the
  # data type of the detail, value is set for it, and its linked
  # to the detail and instnace provided.
  #
  def save_value(instance_id, detail_id, value)
    
    data_type = Detail.find(detail_id).data_type
    # Create the new object of appropiate type.
    detail_value = class_from_name(data_type.class_name).new
    # Link with instance
    detail_value.instance_id = instance_id
    # Link with detail
    detail_value.detail_id = detail_id
    return populate_value(detail_value, data_type, value)
    
  end
  
  # *Description*
  #   Updates a given value
  # It is provided with 
  def update_value(detail_id, value_id, new_value)
    
    puts "detail_id = #{detail_id} AND value_id = #{value_id} AND new_value = #{new_value}"
    detail = Detail.find(detail_id)
    begin
      detail_value = class_from_name(detail.data_type.class_name).find(value_id)
    rescue Exception => e
      raise BadResource.new, "Detail '#{detail.name}' does not have a value with ID #{value_id}"
    end
    
    
    # If the provided value is nil, we need to delete it after checking the vesion
    if !new_value['value']
      if detail_value.lock_version.to_i != new_value['lock_version'].to_i
        raise ObsoleteResource.new, "Attemped to delete stale detail value"
      else
        detail_value.destroy and return nil
      end
    end
    
    return populate_value(detail_value, detail.data_type, new_value)
    
  end
  
  # *Description*
  #   Populatest the given detail value with the given value.
  #   
  # *Arguments*
  #   * +detail_value+ is any object of subclass of +DetailValue+
  #   * +data_type+ object of +DataType+
  #   * +value_to_populate+ is a hash that contains following keys:
  #      * :value         => 'value_to_be_populated'
  #      * :lock_version  => lock_version of detail value if its an update.
  #                           this is optional for save operations but mandatory
  #                           for updates though this method has no way to 
  #                           determine whether its an update or save. This has
  #                           to be decided and determined at upper levels.
  #    OR
  #   * +value_to_populate+ can be a simple value of any type other then Hash 
  #      and its subclasses
  #FIXME: Make this more neat
  def populate_value(detail_value, data_type, value_to_populate)
  
   
    # Fill in the value
    value  = nil
    value = value_to_populate['value'] if value_to_populate.is_a? Hash
    value = value_to_populate if !value_to_populate.is_a? Hash
    
   
    case(data_type.name)
    when  
          'madb_short_text',
          'madb_long_text',
          'madb_email',
          'madb_web_url',
          'madb_date',
          'madb_integer'
        detail_value.value = value
        # if its an attachement, then we need to pick it differently.
    when 'madb_s3_attachment',
        'madb_file_attachment'
         
        #puts "FILE ATTACHMENTN RECIEVED AS #{value}"
        #puts "#{params[value].methods.join(', ')}"
        raise BadResource.new, "Detail '#{detail_value.detail.name}' mentions '#{value}' to " + 
              "contain file attachment which is not provided" if !params[value]
        detail_value.value = params[value]
    when 'madb_choose_in_list'
      populate_proposition_id_for(detail_value, value)
    end
    
    
    
    # Apply lock_version if given
    if value_to_populate.is_a? Hash
      detail_value.lock_version = value_to_populate['lock_version'] if value_to_populate['lock_version']
    end
    
    puts "DetailValueType is #{detail_value.class}"
    # save! method because we want it to raise an exception to be caught by
    # the upper levels.
    detail_value.save!
    #detail_value.save if data_type.name == 'madb_s3_attachment'
    
    return detail_value
  end
  
  def populate_proposition_id_for(detail_value, value)
    # if its numeric, its proposition id, otherwise, we need to get it
      puts "~~~~~~~~~~~~~~~#{value.class.name}~~~~~~~~~~~~~~~~~"
      puts "THE VALUE IS #{value}"
      #value = value.to_s.strip
      #if value =~ /^\d+$/
      if value.is_a? Fixnum
        raise ResourceNotFound.new, "DetailValuePropostion#{value} does not exists" if !DetailValueProposition.exists? value
        detail_value.detail_value_proposition_id = value
      else
        begin
          puts "Going to fetch prop id for #{value}"
          prop = DetailValueProposition.find(:first, :conditions => ["value=? AND detail_id=?", value, detail_value.detail_id])
          detail_value.detail_value_proposition_id = prop.id
          puts "#{value} is #{prop.id}"
        rescue Exception => e
          raise BadResource.new,"'#{value}' is not a possible value for detail[#{detail_value.detail_id}]"
        end
      end
  end
  
  
  # *Description*
  #   This mehtod allows you get a single instance or all isntacnes of an 
  #   entity. The records are returned in json format.
  # The options hash incldues either the instance id in the instancne key if a single
  # instance is needed and entity id if all the instances of an entity are needed.
  # +Options+
  #   +:instance+   : id of the instance to be retrieved.
  #   +:entity+     : id of entity for which to retrive instance. Note that
  #                   only supply either :entity or :instance option but not BOTH!
  #   +:foramt+     : (json, xml) for the links to be returened.
  #   +:offset+     : same as :offset option to the ActiveRecord::Base#find
  #                   used as OFFSET clause of the query. Only applicable if the
  #                   instances are being asked for an entity.
  #   +:limit+      : Same as :limit option to the ActiveRecord::Base#find
  #                   used as LIMIT clause of the query. Only applicable if the
  #                   instances are being asked for an entity.
  #
  def get_records_for(options={})
    sql, records_info = build_query_for(options)
    records = execute_query(sql)
    record_set = build_record_set(records)
    options[:instance_order] = records_info[:instance_ids] if options[:entity]
    records =  record_set_to_json(record_set, options)
    # if the records are for an entity, build proper structure
    if options[:entity]
      instances = {}
      
      instances[:total_resources] = records_info[:total_resources]
      instances[:resources_returned] = records_info[:resources_returned]
      instances[:start_index] = options[:start_index].to_i
      instances[:order_by] = options[:order_by]
      instances[:direction] = options[:direction].downcase if options[:direction]
      instances[:resources] = records
      instances[:resource_type] = 'instance'
      return instances 
    else
      #records[:resource_type] = 'instance'
      return records
    end
  end
  
  # *Description*
  #   This function builds a query for either getting a single instance,
  #   or getting all instances of an entity.
  # Revision Log:
  #   * 10 March, 2008: Modified to add the support for pagination
  #   * 20 March, 2008: Modifed the query to get instance and value lock versions
  #   * 07 May,   2008: Modified the function to do condtional filtering and sorting
  def build_query_for(options={})
    
    condition = ''
    order = ''
    
    # We specify different quries based on wheter we are getting a single
    # instance or all instances of an entity.
    condition = "i.id = #{options[:instance]}" if options[:instance]
    condition = "i.entity_id = #{options[:entity]}" if options[:entity]
    
    # These are the instance ids sorted and filtered 
    instance_ids = []
    
    # if the instances are to be fetched for entity, we need to 
    # modify the conditions in order to support the pagination and others things
    if options[:entity]
      records_info = get_filtered_instance_ids( 
        :entity         => options[:entity],
        :order_by       => options[:order_by],
        :direction      => options[:direction],
        :conditions     => options[:conditions],
        :start_index    => options[:start_index],
        :max_results    => options[:max_results]
          )
          
      instance_ids = records_info[:instance_ids]
       
      # If no instance is found, raise an exception
      if instance_ids.nil? or instance_ids.length == 0
        msg = "No instances found"
        msg += " based on #{options[:conditions]}" if options[:conditions]
        raise msg
      end
      
       condition += " AND i.id IN (#{instance_ids.join(',')})"
#      if options[:offset] or options[:limit]
#        condition += " AND i.id IN (SELECT id FROM instances WHERE instances.entity_id =#{options[:entity]} ORDER BY id"
#        condition += " OFFSET #{options[:offset]}" if options[:offset]
#        condition += " LIMIT #{options[:limit]}" if options[:limit]
#        condition += ')'
#      end
    end
    
    # Ordering clause of the 
    order = 'display_order' if options[:instance]
    order = 'id, display_order' if options[:entity]
    
    
      # These are the tables that we query for the values because:
      # Simple text values are stored in detail_values
      # Integer values are in integer_detail_values
      # Date values are in date_detail_values
      dt = [ "detail_values", "integer_detail_values", "date_detail_values"]
      columns = 'i.id, i.lock_version as instance_version, d.id as detail_id, d.name, dt.name as data_type, v.id as detail_value_id, v.lock_version as value_version, v.value::text, e2d.display_order'
      # Here we list the columns that we want to have.
      

      #FIXME: Soem tables can be take out of join:
      #   * entities2details. currently needed because need the display order.
      #   * entities
      #   * data_types?? (not possible due to integer, date and ddl value types)
      query = dt.inject("") do  |q, t|
      q += %Q~SELECT #{columns}  
              FROM #{t} v 
              JOIN details d ON (v.detail_id = d.id) 
              JOIN instances i ON (i.id=v.instance_id) 
              JOIN entities e ON (e.id=i.entity_id) 
              JOIN entities2details e2d ON (e2d.detail_id=d.id and e2d.entity_id = e.id)   
              JOIN data_types dt ON (d.data_type_id=dt.id)
              WHERE #{condition} UNION ~
      end

      # And this is for 
      query += %Q~SELECT i.id, i.lock_version as instance_version,  d.id as detail_id, d.name, dt.name as data_type, v.id as detail_value_id, v.lock_version as value_version, p.value::text, e2d.display_order  
                  FROM ddl_detail_values v 
                  JOIN details d ON (v.detail_id = d.id) 
                  JOIN detail_value_propositions p ON (p.id=v.detail_value_proposition_id) 
                  JOIN instances  i ON (i.id=v.instance_id) 
                  JOIN entities e ON (e.id=i.entity_id) 
                  JOIN entities2details e2d ON (e2d.detail_id=d.id and e2d.entity_id = e.id)  
                  JOIN data_types dt ON (d.data_type_id=dt.id)
                  WHERE #{condition} ORDER BY #{order}~

      return [query, records_info]
    
    
  end
  
  # *Description*
  #  This method executes the given query and returns an array of records where
  # Each record is accessible through its name. For instance, if you execute
  # following query:
  # SELECT * FROM entities;
  # 
  # Then the return object is has following formation:
  # record[0][:id]      # id of the first record
  # record[0][:database_id]    # name in the first record
  # record[][:name]
  # record[0][:has_public_form]
  #
  # And so on and so forth
  def execute_query(sql)
    return CrosstabObject.find_by_sql(sql)
  end
  
  # *Description*
  #   Given records which are obtained by executing query on database, this 
  #   function builds a custom structure which is a hash of hashes.
  #   
  #                     *DATA_STRUCTURE_FORMATION*
  # All the records are kept in a hash indexed by the instance id like this:
  # record_set[18]  # contains the reocrd with instance id 18
  # Each record is further hash of columns each index by column names.
  # Each column indexed by its name has four attributes:
  #    * detail_id
  #    * data_type
  #    * display_order
  #    * values
  #    
  #  detail_id is the id of the detail. data_type is the datatype of the detail.
  #  display_order is the order of the detail while being displayed(to be processed 
  #  at interface levels).
  #  
  #  For a better epplanation, please look this chart below:
  #  
  #  record[:id] (one or more)
  #    |
  #    +---lock_version (lock_version of instance)
  #    |
  #    +---col_name (one or more)
  #          |
  #          +---detail_id
  #          +---data_type
  #          +---display_order
  #          +---values (one or more)
  #                |
  #                +---id
  #                +---lock_version
  #                +---value
  #    
  #
  
  def build_record_set(records)
    
    #columns = {}
    record_set = {}
    
    records.each do |record|
      
      #If the record with the given id does not exsits, 
      # create it
      record_set[record[:id]] = {} if !record_set[record[:id]]
      
      # Create the hash for the field if it does not exists.
      record_set[record[:id]][record[:name]] = {} if !record_set[record[:id]][record[:name]]
      record_set[record[:id]][:lock_version] = record[:instance_version]
      record_set[record[:id]][record[:name]][:detail_id] = record[:detail_id]
      record_set[record[:id]][record[:name]][:data_type] = record[:data_type]
      record_set[record[:id]][record[:name]][:display_order] = record[:display_order]
      # Create the array of values
      record_set[record[:id]][record[:name]][:values] = [] if !record_set[record[:id]][record[:name]][:values]
      record_set[record[:id]][record[:name]][:values].push({:id => record[:detail_value_id], :lock_version => record[:value_version], :value => record[:value]})
    end
    
    return record_set
    
  end
  
    # *Description*
  #    Transforms a recordset to json according to the following format:
  #   { 
  #     name: [
  #             { id: 4535, value: "Mohsin"}
  #           ], 
  #           
  #     phone: [ 
  #             {id: 6245, value: '321676465'}, 
  #             {id:6247, value: "001343543"} 
  #            ] 
  #   }
  #
  # *Workflow*
  #   The first argument is a hash with having the id of the instance as
  #   the key and the value is the record. Please look the +build_record_set+()
  #   for details on this.
  #   
  #   For each of the record, the values of each of its columns are retrived and
  #   converted to json by +json_for_values+()
  #   options:
  #     * +:format+ in which the urls should end
  #     * +:instance_order+ is an array of instace ids which specify the ordering
  # FIXME: This method should not generate JSON directly instead
  # should structure its output hashs etc.
  def record_set_to_json(record_set, options={})
    
    format = ''
    format = '.' + options[:format] if options[:format]
    
    entity_id = ''
    # Because the get_records_for() method will always be called with either option
    # of :instance => id or :entity => id, we try to get the id of the entity
    # here
    entity_id = options[:entity] if options[:entity]
    entity_id = Instance.find(options[:instance]).entity_id if options[:instance]
    
    instance_ids = record_set.keys if !options[:instance_order]
    instance_ids = options[:instance_order] if options[:instance_order]
    
    instances = []
    #+ 
    # For each of the record
    instance_ids.each do |id|
    
      record = record_set[id]
      next if !record
      #instance = {}
      #FIXME: The way we're populating an instance variable, detail model
      # needs to have some contraints about how they can be named
      instance = Instance.new
      
      
      # Add the details url
      # If a single instance was asked by the get_records_for then instances url otherwise entity
      #If you uncomment these two lines of code , the url will be depnding upon whether records are being
      #retrieved for an entity or a single instance
      #details_url = (@@lookup[:Instance] % [@@base_url, options[:instance]]) if options[:instance]
      #details_url = (@@lookup[:Entity] % [@@base_url, options[:entity]]) if options[:entity]
      
      #details_url = (@@lookup[:Entity] % [@@base_url, entity_id])
      #details_url += (@@lookup[:Detail] % ['', '']).chop + format
      #entity_url = (@@lookup[:Entity] % [@@base_url,entity_id]) + format
      #links_url = (@@lookup[:Instance] % [@@base_url, id])
      #links_url += (@@lookup[:Link] % ['', '']).chop + format
      
      #instance[:url] = @@lookup[:Instance] % [@@base_url, id.to_s] + format
      #instance[:entity_url] = entity_url
      #instance[:details_url] = details_url
      #instance[:links_url] = links_url      
      
      instance[:id] = id
      instance[:entity_id] = entity_id
      instance[:lock_version] = record_set[id][:lock_version].to_i

      # For each of the columns
      record.each do |col_name, values|
        # if its lock_version, its reserved name, skip it!
        next if col_name.to_s == 'lock_version'
        instance[col_name] = json_for_values(values, options)
      end
      # Add to instances
      instances << instance
      
    end
    
    if options[:instance]
      instances = instances[0]
    end
    
    return instances
  end
  
  # *Description*
  #   Converts the values to json
  # This functino is used by the +record_set_to_json+() function in order
  # to convert the values into json.
  # 
  # *Arguments*
  #   +values+
  #     A hash that has following formation:
  #   values[:detail_id]        id of the detail
  #   values[:data_type]        id of the data type of detail
  #   values[:display_order]    display order of the detail
  #   values[:values]           The array of hashes each hash contains id and values
  #   The values[:values] is an array of hashes where each hash has following
  #   structure:
  #     values[:values][0][:id]       id of the first value 
  #     values[:values][0][:value]    value of the first value 
  #     
  #   +options+
  #     These are the same options that are passed to +get_records_for+
  #     But only the :format option is important which is used to determine the
  #     type of the extension to be appened with url.
  # *Workflow*
  #   Over the array of the values, each id of the value and the value itself
  # obtained and depending upon the datatype of the value, appropiate JSON is 
  # generated.
  # FIXME: What should it do for FileAttachment and S3Attachment
  # For S3, we give it the download URL
  def json_for_values(values, options={})
    format = ''
    format = '.' + options[:format] if options[:format]
    json = []
    # For each of the values
    values[:values].each do |value|
      
      json_value = {}
      #json_value[:url] = "#{@@base_url}/details/#{values[:detail_id]}/values/#{value[:id]}#{format}"
      json_value[:id] = value[:id]
      json_value[:detail_id] = values[:detail_id]
      json_value[:data_type] = values[:data_type]
      json_value[:lock_version] = value[:lock_version].to_i
     
      case values[:data_type]
      when 'madb_integer'
        json_value[:value] = value[:value].to_i
      when 'madb_s3_attachment'
        s3 = S3Attachment.find(value[:id])
        json_value[:value] = s3.download_url
      when 'madb_file_attachment'
        # In case of simple FileAttachment, provide the link of this detail value
        # So that user can download it from there
        json_value[:value] = "#{@@base_url}/details/#{values[:detail_id]}/values/#{value[:id]}"
      else
        json_value[:value] = value[:value]
      end
      json << json_value
    end
    
    return json
  end
  
  
  # FIXME: This method shouuld be in proper module
  def destroy_item(klass, item_id, lock_version)
    item = klass.find item_id
    
    if item.lock_version.to_i != lock_version.to_i
      msg = "Attempted to delete a stale object"
      raise ActiveRecord::StaleObjectError.new, msg
    end
    
    item.destroy
    
  end
  
    # *Description*
  # DELETEs a given value
  def destroy_value(detail_id, value_id, lock_version)
    value = class_from_name(Detail.find(detail_id).data_type.class_name).find(value_id)
    
    if lock_version.to_i != value.lock_version.to_i
      raise ActiveRecord::StaleObjectError.new, "Attempted to delete a stale object"
    end
    value.destroy
    
    #class_from_name(Detail.find(detail_id).data_type.class_name).delete(value_id)
  end
  

  # *Description*
  # Returns the paginated records for the given resorces
  # Currently its upto the consumer of the API to provide correct column names
  # for ordering and conditions 
  # A Hash of paramters
  #  * :for => klass (i.e Detail, Entity etc)
  #  * :start_index
  #  * :max_results
  #  * :order_by defaults to id
  #  * :direction    defaults to ASC
  #  * :conditions
  #   * If you want to get Instances, you need to provide Instance in :for key and
  #     you also need to mention the entity id in :entity key
  #   * If you want detail values, you need to mention DetailValue in :for key
  #     and also need to mention instance id and detail id in :instance_id and
  #     :detail_id keys respectively
  def get_paginated_records_for(options = {})
    
    # If no class provided, return
    if !options[:for]
      return nil
    end
    
    # table is basically a model in our application
    table = options[:for]
    
    # If the table is DetailValue, then we are acutally getting the detail values
    # In this case, we must have:
    # * instance_id
    # * detail_id
    # 
    if table == DetailValue
      msg = "get_paginated_records_for() needs instance_id while getting DetailValues"
      raise MadbException.new(500), msg, caller if !options[:instance_id]
      msg = "get_paginated_records_for() needs detail_id while getting DetailValues"
      raise MadbException.new(500), msg, caller if !options[:detail_id]
      # Now find the correct underlying table
      table = class_from_name(Detail.find(options[:detail_id]).data_type.class_name)
    end
    
    order_clause = nil
    
    

    # If the order by columns are provided by the user then
    if !options[:order_by].nil? or options[:order_by].to_s.strip != ''
      
      # Default ordering will be ascending if not provided by the user
      if !options[:direction] or options[:direction].to_s.strip == ''
        options[:direction] = 'ASC'
      end
      
      # Remove non colums and make an order clause
      cols = remove_non_columns_for(table,options[:order_by], :ordering)
      order_clause = "#{cols} #{options[:direction]}" if cols.strip != ''
    end
    
    # If the instances are being asked, and entity is not mentioned,
    if table == Instance
      return nil if !options[:entity]
      return get_records_for(options)
    end
    
    result_set = {}
    
    puts "CONDITIONS ARE: #{options[:conditions]}"
    results = table.find(:all, 
      :offset => options[:start_index],
      :limit => options[:max_results],
      :order => order_clause,
      :conditions => options[:conditions]
    )
    
    # If the conditions are provided, make a conditional call
    count_sql = "SELECT COUNT(*) FROM #{table.table_name}"
    count_sql += " WHERE #{options[:conditions]}" if options[:conditions]
    
    if options[:for].superclass == DetailValue or options[:for] == DetailValue
      options[:for] = 'value' 
    else
      options[:for] = options[:for].name.underscore
    end
    # Resource type is used by partials to render appropiate partial
    result_set[:resource_type] = options[:for]
    result_set[:resources_returned] = results.length
    result_set[:total_resources] = table.count_by_sql(count_sql)
    result_set[:start_index] = options[:start_index].to_i
    result_set[:order_by] = options[:order_by]
    result_set[:direction] = options[:direction].downcase if options[:direction]
    result_set[:conditions] = options[:conditions]
    result_set[:resources] = results
    
    
    return result_set
  end
  
  # *Description*
  #  Concatenates two conditions 
  def add_condition(old_condition, new_condition, operation)
    
    return nil if operation.to_s.strip == ''
    
    if old_condition.to_s.strip == ''
      return new_condition
    end
    
    if new_condition.to_s.strip == ''
      return old_condition
    end
    
    return old_condition + " #{operation.to_s.upcase} "  + new_condition
  end
  
  # *Description*
  #   Removes non columns from list of columns for given type
  # The list of columns is basically provided by the consumer of the API
  # for sake of ordering
  #PENDING: Add functionality for validating against an instance
  def remove_non_columns_for(klass, columns, removal_for)
     columns.split(',').collect{|col| col.strip if klass.column_names.include?(col.strip)}.compact.join(', ')
  end
  
  # Builds and returns a cross tab query
  def crosstab_query_for_entity(entity_id, h = {})
    
    defaults = { :display => "detail" }
    not_in_list_fields = []
    details_kept = []

    options = defaults.update h
    entity = Entity.find entity_id
    details_select = ""
    as_string = "id int "
    entity.details.sort{ |a,b| a.name.downcase <=>b.name.downcase }.each do |detail|
      #entity_detail = EntityDetail.find :first, :condition => ["entity_id = ? and detail_id =?",entity.id, detail.id]
      if detail.displayed_in_list_view=='f'
        not_in_list_fields.push detail.name.downcase
        next if options[:display]=="list"
      end
      details_kept.push detail
      details_select += " UNION SELECT ''#{detail.name.downcase}''"
      case detail.data_type.name
      #  when "short_text"
      #  when "long_text"
      #  when "date"
         when "madb_integer"
          as_string += ",  \"#{detail.name.downcase}\" bigint "
      #  when "choose_in_list"
         else
          as_string += ",  \"#{detail.name.downcase}\" text "
      end
    end

    if details_select.length==0
      return nil
    else
      h = { :values_query =>"SELECT DISTINCT ON (i.id, d.name) i.id, LOWER(d.name) AS name, dv.value FROM instances i JOIN detail_values dv ON (dv.instance_id=i.id) JOIN details d ON (d.id=dv.detail_id) WHERE i.entity_id=#{entity_id}
      UNION SELECT DISTINCT ON (i.id, d.name) i.id, LOWER(d.name) AS name, dv.value::text FROM instances i JOIN date_detail_values dv ON (dv.instance_id=i.id) JOIN details d ON (d.id=dv.detail_id)  WHERE i.entity_id=#{entity_id}
      UNION SELECT DISTINCT ON (i.id, d.name) i.id, LOWER(d.name) AS name, dv.value::text FROM instances i JOIN integer_detail_values dv ON (dv.instance_id=i.id) join details d ON (d.id=dv.detail_id) WHERE i.entity_id=#{entity_id}
      UNION SELECT DISTINCT ON (i.id, d.name) i.id, LOWER(d.name) AS name, pv.value FROM instances i JOIN ddl_detail_values dv JOIN detail_value_propositions pv ON (pv.id=dv.detail_value_proposition_id)  ON (dv.instance_id=i.id) JOIN details d ON (d.id=dv.detail_id)  WHERE i.entity_id=#{entity_id} ORDER BY id, name",
      :details_query => details_select.sub!(/UNION/,""),
      :as_string => "#{as_string}" }
      #[ "crosstab('#{h[:values_query]}', '#{h[:details_query]}') as (#{h[:as_string]})", not_in_list_fields ]
      return { 
        :query => "crosstab('#{h[:values_query]}', '#{h[:details_query]}') as (#{h[:as_string]})", 
        :not_in_list_view => not_in_list_fields, 
        :ordered_fields => details_kept.sort{|a,b| a.display_order<=>b.display_order}.collect{|d| d.name.downcase }}
    end
  end
  
  # *Description*
  #   This function retusn the instance ids after applying:
  #     * ordering on given fields and of given type
  #     * conditions on values
  #     * and pagination.
  #     
  #  options:
  #   * +:entity+         => entity id for which to get instances
  #   * +:order_by+      => name of fields separated by , on which to order
  #   * +:direction+      => asc or desc
  #   * +:conditions+     => conditions same as you'd put in WHERE clause of a SQL
  #                        statement. Note that all field names should be in lower case!
  #   * +:start_index+    => start index of records
  #   * +:max_results+    => max_results
  #   
  #  *Returns*
  #    A hash containing following keys:
  #      * +:instance_ids+    is an array of ids sorted and filtered
  #      * +:resources_returned+ is the number records being returned
  #      * +:total_resources+ total resources that full fuil the criterea
  #
  def get_filtered_instance_ids(options={})
    
    # if entity not provided, return
    return nil if !options[:entity]
    
    crosstab_query = crosstab_query_for_entity(options[:entity])
    
    # If not able to get the query, just return
    return nil if !crosstab_query
    
    conditions = ''
    conditions = " WHERE #{options[:conditions]}" if options[:conditions]
    
    # Build the main query
    query = "SELECT id FROM #{crosstab_query[:query]} #{conditions}"
    
    
    
    #if order is provided
    if options[:order_by]
      query += " ORDER BY #{options[:order_by]} #{options[:direction]}"
    end
    
    # At this place, if the user has provided any conditions, we get 
    # the count of the records with conditiosn applicable.
    # This is needed because just teh lenghth of the array prepared 
    count_query = "SELECT COUNT(*) FROM #{crosstab_query[:query]} #{conditions}"
    record_count = ActiveRecord::Base.connection.execute(count_query)[0][0]
    
    
    # If the options for pagination are provided
    if options[:start_index] or options[:max_results]
      query += " OFFSET #{options[:start_index]}" if options[:start_index]
      query+=  " LIMIT #{options[:max_results]}" if options[:max_results]
    end
    
    ids = ActiveRecord::Base.connection.execute(query)
    
    a = ids.result.collect{|id| id[0].to_i}
    
    return {:instance_ids => a, :resources_returned => a.length.to_i, :total_resources => record_count.to_i}
  end
  
  def make_conditions_for_sql(conditions={})
    # For each condition in the array
    # if its a hash and contains a
    
    msg = "More then one logical operator provided for top level condtions"
    raise ArgumentError.new, msg if conditions.keys.length > 1
    
    # Get the condition operator
    operator = conditions.keys[0]
    c = ''
    # For each provided condition
    sql_condition = ''
    conditions[operator].each do |condition| 
      # If the condtion contains operator as key
      if condition[:or] or condition[:and]
        c = make_conditions_for_sql(condition)
        if sql_condition == ''
          sql_condition = c 
        else
          sql_condition += " #{operator.to_s} #{c}"
        end
      else
        
        condition.each do |key, value|
          c += "#{key.to_s}=#{value.to_s} AND "
        end
        sql_condition = c.chomp(' AND ')
      end
    end
    
    return sql_condition
    
  end
  

end