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

  # REST shoudl be disable while running the tests.
  # REST shold also be disabled if you are accessing the application from the 
  # old interface.
enable_rest = true


#                                *REST_API_REFERENCE_CHART*
#                                
#  *Resources*
#    Below is the list of resources available so far. The respective id of each resourec
#    just after it is implicit. For the last resource, its always :id otherwise
#    its of the form :SingularFormOfResource_id like for entities, its :entity_id
#    
#    TODO: Add the route for links!
#  *  /accounts
#  *  /accounts/users
#  *  /account_types (proposed)
#  *  /account_types/account_type_values(proposed)
#  *  /data_types
#  *  /entities
#  *  /entities/details
#  *  /entities/instances
#  *  /entities/instances/details/
#  *  /entities/relations
#  *  /details
#  *  /details/status (proposed) would be propagated on all levels
#  *  /details/detail_value_propositions (proposed)
#  *  /databases
#  *  /databases/details
#  *  /databases/entities
#  *  /databases/entities/details
#  *  /databases/entities/instances
#  *  /databases/entities/relations
#  *  /instances (proposed)
#  *  /instances/details/ (proposed)
#  *  /instances/details/detail_values (proposed)
#  *  /instances/details/ddl_detail_values (proposed)
#  *  /instances/details/date_detail_values (proposed)
#  
#  
#

  # For each resoruce exposed, you get following methods:
  # _url full URL has a formatted version also
  # _path only path has a formatted version also
  # 
  # hash_for would return which controller, method etc.
  # For exmaple, if you exposed resource databases wtih following:
  # map.resources :databases
  # Then you have following:
  # databases_url
  # databases_path
  # hash_for_databases_url
  # hash_for_databases_path
  # formatted_databases_url
  # formatted_databases_path
   
  
  
  if enable_rest == true then
    
    resources :data_types, :singular => 'data_type', :controller => 'rest/data_types'
    
    resources :databases, :singular => 'database', :controller => 'rest/databases' do |database|
      database.resources :entities, :singular => 'entity', :controller => 'rest/entities'
      database.resources :details , :singular => 'detail', :controller => 'rest/details'
    end
    
    resources :entities, :singular => 'entity', :controller => 'rest/entities' do |entity|
      entity.resources :details, :singular => 'detail', :controller => 'rest/details'
      entity.resources :instances, :singular => 'instance', :controller => 'rest/instances'
      entity.resources :relations, :singular => 'relation', :controller => 'rest/relations'
    end
    
    resources :details, :singular => 'detail', :controller => 'rest/details' do |detail|
      detail.resources :propositions, :singular => 'proposition', :controller => 'rest/propositions'
      # Useless
      #detail.resources :values, :singular => 'value', :controller => 'rest/values'
    end
    
    resources :instances, :singular => 'instance', :controller => 'rest/instances' do |instance|
      instance.resources :links, :singular => 'link', :controller => 'rest/links'
      instance.resources :details, :singular => 'detail', :controller => 'rest/details' do |detail|
        detail.resources :values, :singular => 'value', :controller => 'rest/values'
      end
    end
    
    resources :links, :singular => 'link', :controller => 'rest/links'
    
    resources :relations, :singular => 'relation', :controller => 'rest/relations'
    resources :relation_side_types, :singular => 'relation_side_type', :controller => 'rest/relation_side_types'
    
    resources :users, :singular => 'user', :controller => 'rest/users'
    resources :user_types, :singular => 'user_type', :controller => 'rest/user_types'
    
    resources :accounts, :singular => 'account', :controller => 'rest/accounts' do |account|
      account.resources :users, :singular => 'user', :controller => 'rest/users'
      account.resources :databases, :singular => 'database', :controller => 'rest/databases'
    end
    
    resources :account_types, :singular => 'account_type', :controller => 'rest/account_types'
    
    
    resources :propositions, :singular => 'proposition', :controller => 'rest/propositions'
    resources :detail_statuses, :singular => 'detail_status', :controller => 'rest/detail_statuses'
    
    
  end

