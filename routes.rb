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

ActionController::Routing::Routes.draw do |map|


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
  if enable_rest == true then
    
    map.resources :data_types, :singular => 'data_type', :controller => 'rest/data_types'
    
    map.resources :databases, :singular => 'database', :controller => 'rest/databases' do |database|
      database.resources :entities, :singular => 'entity', :controller => 'rest/entities'
      database.resources :details , :singular => 'detail', :controller => 'rest/details'
    end
    
    map.resources :entities, :singular => 'entity', :controller => 'rest/entities' do |entity|
      entity.resources :details, :singular => 'detail', :controller => 'rest/details'
      entity.resources :instances, :singular => 'instance', :controller => 'rest/instances'
      entity.resources :relations, :singular => 'relation', :controller => 'rest/relations'
    end
    
    map.resources :details, :singular => 'detail', :controller => 'rest/details' do |detail|
      detail.resources :propositions, :singular => 'proposition', :controller => 'rest/detail_value_propositions'
      # Useless
      #detail.resources :values, :singular => 'value', :controller => 'rest/values'
    end
    
    map.resources :instances, :singular => 'instance', :controller => 'rest/instances' do |instance|
      instance.resources :links, :singular => 'link', :controller => 'rest/links'
      instance.resources :details, :singular => 'detail', :controller => 'rest/details' do |detail|
        detail.resources :values, :singular => 'value', :controller => 'rest/values'
      end
    end
    
    map.resources :links, :singular => 'link', :controller => 'rest/links'
    
    map.resources :relations, :singular => 'relation', :controller => 'rest/relations'
    map.resources :relation_side_types, :singular => 'relation_side_type', :controller => 'rest/relation_side_types'
    
    map.resources :users, :singular => 'user', :controller => 'rest/users'
    map.resources :user_types, :singular => 'user_type', :controller => 'rest/user_types'
    
    map.resources :accounts, :singular => 'account', :controller => 'rest/accounts' do |account|
      account.resources :users, :singular => 'user', :controller => 'rest/users'
      account.resources :databases, :singular => 'database', :controller => 'rest/databases'
    end
    
    map.resources :account_types, :singular => 'account_type', :controller => 'rest/account_types'
    
    
    map.resources :propositions, :singular => 'proposition', :controller => 'rest/detail_value_propositions'
    map.resources :detail_statuses, :singular => 'detail_status', :controller => 'rest/detail_statuses'
    
    
  end
end
