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

#net/http doc
#
require 'rubygems'
require 'erb'
require 'json'
require 'net/http'
require 'active_support/core_ext/string/inflections.rb'


include ERB::Util

#####################################################
# NOTE: SEE SAMPLE PROGRAM AT THE END!
#####################################################
#
#
# We modify the string class to convert the urls to ids
class String
  include ActiveSupport::CoreExtensions::String::Inflections
   def to_id
     self.chomp('.json')[/[0-9]+$/].to_i
   end
end


module Dedomenon
    class Connection

        def initialize(login,password)
             @con = Net::HTTP.new('localhost',3000)
             response = @con.post('/authentication/login', "user[login]=#{login}&user[password]=#{password}")
             case response.code.to_i 
                when 200,302
                    @session_cookie=response["Set-Cookie"]
                else
                    raise "Connection error"
             end
        end

        def get(url, klass=nil)
            puts "fetching #{url} to class #{klass}"
            response=@con.get(url, "Cookie" => @session_cookie)
            puts response.body
             case response.code.to_i 
                when 200,302
                    json = JSON.parse(response.body)
                    if klass.nil?
                        return json
                    else
                      if json.is_a?(Array)
                        # new set to false as it comes out of the database
                        return json.collect{|d| klass.new(:data => d, :con => self, :new => false)}
                      elsif json.is_a?(Hash)
                        return klass.new(:data => json, :con => self)
                      end
                    end
                else
                    raise "Database retrieval error"
             end
        end
        
        def post(url, data)
          puts "POST #{data} to #{url}"
          response = @con.post(url, data, 'Cookie' => @session_cookie)
          puts "Status: #{response.code}"
          puts response.body
          
          case response.code.to_i
          when 200..302
            begin
              urls  = JSON.parse(response.body)
            rescue Exception => e
              urls = [response.body]
            end
            return urls
          else
            raise "Faild in saving data!"
          end
          
        end
        
        def delete(url)
          puts "Executing DELETE #{url}"
          response = @con.delete(url,  'Cookie' => @session_cookie)
          puts response.body
          
          case response.code.to_i
          when 200, 302
            return response.body
          else
            raise "#{response.body}"
          end
        end
        


        def databases
            get("/databases.json", Database)
        end

        #get all datatypes, and return them in a hash with the key being the name of the detail, eg madb_short_text
        def data_types
            types = get("/data_types.json", Database)
            r= {}
            types.collect{ |t|  r[t['name']] = t} 
            return r
        end

    end

    class Base
      
        def self.links_to(h)
            module_eval(%{
                def #{h[:method]}
                    r = @con.get(@data["#{h[:method]+'_url'}"], #{h[:class_name]}  )
                    #{h[:single]? "r[0]":"r"}
                end 
            })
        end
        
        def self.located_at(location)
          module_eval(%{
              def url
                '#{location}'
              end
            })
        end
        
        def initialize(h)
            @con = h[:con]
            @data = {}
            @data = h[:data] if h[:data]
            #flag to know if we need to post or put when saving
            @new = h[:new].nil? ? true:h[:new]
        end

        #I've made some modification to this method but I'm sure you'll not 
        # like them ;-)
        # What I'm doing:
        #  * If you call with empty brackets, you'll get ALL (not works in all cases... i.e. for nested resources)
        #  * if you call with a number, you'll get a the object with that id -> This should be done by instanciating a new object, not by using another object. Raph
        #  * if you call with a string or symbol, you'll get the value of that field.
        # Mohsin.
        def [](key)

          # if its a string, convert it to number
          key = key.to_s if key.is_a? Symbol
          
          # if not index via number, get attribute
          return @data[key] if key.is_a? String

        
          
          #return @con.get(url + '.json', self.class) if key==nil
          
          # This should be done by instanciating the class wanted. Mohsin, can you remove and adapt possibly depending code?
          return @con.get(self.url + "/#{key}.json", self.class)
          
        end
        
        # modify the attributes from here.
        def []=(key, value)
          @data[key] = value
        end
        
        # return the fields so that we can iterate on them
        def fields
          @data
        end
        
          
        def url
          '/' + self.class.name.pluralize.underscore.split('/').last
        end

        def post_url
            url+".json"
        end

        
        def param_name
          self.class.name.underscore.split('/').last
        end
        
        def save
          data =  "#{self.param_name}="+ url_encode(@data.to_json)
          
          if @new
            # the post_url method has to be defined in each class.
            urls = @con.post(post_url, data)
            @data = @con.get(urls[0], self.class).fields
          else
              raise "Not implemented yet"
          end
        end
        
        
    end


    class Account < Base
      
      links_to :method => 'users', :class_name => 'User'
      links_to :method => 'databases', :class_name => 'Database'
      links_to :method => 'account_type', :class_name => 'AccountType'
    end
    
    class Database < Base
      
      links_to :method => "entities", :class_name => "Entity"
      links_to :method => "details", :class_name => "Detail"
      links_to :method => "account", :class_name => "Account"


      def initialize(h)
        super(h)
      end
      
    end

    class DataType < Base
    end

    class Detail < Base
      
      links_to :method => "data_type", :class_name => "DataType"
      links_to :method => "status", :class_name => "DetailStatus"
      links_to :method => "database", :class_name => "Database"
      links_to :method => "propositions", :class_name => "DetailValueProposition"
    end
    
    class DetailValueProposition < Base
      
      located_at '/propositions'
      
      links_to :method => 'detail', :class_name => 'Detail', :single => true
      
    end
    
    class Entity < Base
      links_to :method => "details", :class_name => "Detail"
      links_to :method => "database", :class_name => "Database", :single => true
      links_to :method => "instances", :class_name => "Instance"
      links_to :method => "relations", :class_name => "Relation"
      
      # FIXME: improve this!
      def link_detail(detail, max_values = 1, status_url= '1')
        detail_id = nil
        
        detail_id = detail if detail.is_a?(Fixnum)
        detail_id = detail['url'].to_id if detail.is_a?(Dedomenon::Detail)
        detail_id = detail.to_i if detail.is_a?(String)
        
        raise 'Bad detail' if !detail_id
        raise 'Entity itself does not exists' if !@data['url']
        
        url = self.url + "/#{@data['url'].to_id}/details.json"
        data = 'detail=' + url_encode(%Q~{"detail_id": #{detail_id},"maximum_number_of_values": #{max_values},
          "status_url": "#{status_url}"
        }
        ~)
        
        @con.post(url, data)
      end
      
      def unlink_detail(detail)
        detail_id = nil
        
        detail_id = detail if detail.is_a?(Fixnum)
        detail_id = detail['url'].to_id if detail.is_a?(Dedomenon::Detail)
        detail_id = detail.to_i if detail.is_a?(String)
        
        raise 'Bad detail' if !detail_id
        raise 'Entity itself does not exists' if !@data['url']
        
        url = self.url + "/#{@data['url'].to_id}/details/#{detail_id}.json"
        
        @con.delete(url)
      end
      
    end

    class Instance < Base
      
      links_to :method => "entity", :class_name => "Entity", :single => true
      links_to :method => "details", :class_name => "Detail"
      links_to :method => 'links', :class_name => 'Link'
    end
    
    class Link < Base
      
      links_to :method => 'parent', :class_name => 'Instance', :single => true
      links_to :method => 'child', :class_name => 'Instance', :single => true
      links_to :method => 'relation', :class_name => 'Relation', :single => true
    end
    
    class Relation < Base
      
      links_to :method => 'parent', :class_name => 'Entity', :single => true
      links_to :method => 'child', :class_name => 'Entity', :single => true
      links_to :method => 'parent_side_type', :class_name => 'RelationSideType', :single => true
      links_to :method => 'child_side_type', :class_name => 'RelationSideType', :single => true
      
    end
    
    class RelationSideTypes < Base
    end
    
    class User < Base
    end

end

#@c= Dedomenon::Connection.new('rb@raphinou.com','password')

################################################################
#
#                          SAMPLE PROGRAM
#             
################################################################
#
# This is the Dedomenon GUI Client which will let the user handles its
# databases in Dedomenon Engine through HTTP connection.

#require 'csv'
#require '/home/mohsinhijazee/Projects/Ruby/Rails/madb/trunk/lib/rest/dedomenon.rb'
#
#def create_databases(connection)
#  account = Dedomenon::Account.new(:con => connection)
#
## CREATE A NEW ACCOUNT
#account[:name] = 'REST Demo Account'
#account[:country] = 'Pakistan'
#account[:account_type_url] = '1.json'
#account.save
#
## A NEW USER
## mohsin@yahoo.com with myveryowndb passwrod
#email = 'mohsin@yahoo.com'
#mohsin = Dedomenon::User.new(:con => connection)
#mohsin[:account_url] = account['url']
#mohsin[:user_type_url] = '1.json'
#mohsin[:login] = email
#mohsin[:login_confirmation] = email
#mohsin[:email] = email
#mohsin[:password] = 'myveryowndb'
#mohsin[:password_confirmation] = 'myveryowndb'
#mohsin[:firstname] = 'Mohsin'
#mohsin[:lastname] = 'Hijazee'
#mohsin.save
#
## Database
## CD Collection
#cd_collection = Dedomenon::Database.new(:con => connection)
#cd_collection[:name] = 'CD Collection'
#cd_collection.save
#
## THREE ENTITIES
## CDs, Artists, Tracks
#
#entities = {:CDs => nil, :Artists => nil, :Tracks => nil}
#entities.each do |entity_name, entity|
#  entity = Dedomenon::Entity.new(:con => connection)
#  entity[:database_url] = cd_collection['url']
#  entity[:name] = entity_name
#  entity.save
#  entities[entity_name] = entity
#end
#
#
## The data types:
#text_type = 'http://localhost:3000/data_types/1.json'
#long_text_type = 'http://localhost:3000/data_types/2.json'
#date_type = 'http://localhost:3000/data_types/3.json'
#integer_type = 'http://localhost:3000/data_types/4.json'
#ddl_type = 'http://localhost:3000/data_types/5.json'
#email_type ='http://localhost:3000/data_types/6.json'
#
#status_active = 'http://localhost:3000/detail_statuses/1.json'
#status_inactive = 'http://localhost:3000/detail_statuses/2.json'
#
## Create Details
#title_detail = Dedomenon::Detail.new(:con => connection)
#title_detail[:name] = 'Title'
#title_detail[:data_type_url] = text_type
#title_detail[:status_url] = status_active
#title_detail[:database_url] = cd_collection['url']
#title_detail.save
#
#length_detail = Dedomenon::Detail.new(:con => connection)
#length_detail[:name] = 'Length'
#length_detail[:data_type_url] = text_type
#length_detail[:status_url] = status_active
#length_detail[:database_url] = cd_collection['url']
#length_detail.save
#
#name_detail = Dedomenon::Detail.new(:con => connection)
#name_detail[:name] = 'Name'
#name_detail[:data_type_url] = text_type
#name_detail[:status_url] = status_active
#name_detail[:database_url] = cd_collection['url']
#name_detail.save
#
#date_detail = Dedomenon::Detail.new(:con => connection)
#date_detail[:name] = 'Year'
#date_detail[:data_type_url] = date_type
#date_detail[:status_url] = status_active
#date_detail[:database_url] = cd_collection['url']
#date_detail.save
#
#birthday_detail = Dedomenon::Detail.new(:con => connection)
#birthday_detail[:name] = 'Birthday'
#birthday_detail[:data_type_url] = date_type
#birthday_detail[:status_url] = status_active
#birthday_detail[:database_url] = cd_collection['url']
#birthday_detail.save
#
#notes_detail = Dedomenon::Detail.new(:con => connection)
#notes_detail[:name] = 'Notes'
#notes_detail[:data_type_url] = date_type
#notes_detail[:status_url] = status_active
#notes_detail[:database_url] = cd_collection['url']
#notes_detail.save
#
##FIXME THIS IS GOING TO BE CHALLENGING IN CREATION OF INSTANCES
#number_of_disks = Dedomenon::Detail.new(:con => connection)
#number_of_disks[:name] = 'Number of Disks'
#number_of_disks[:data_type_url] = ddl_type
#number_of_disks[:status_url] = status_active
#number_of_disks[:database_url] = cd_collection['url']
#number_of_disks.save
#
#one = Dedomenon::DetailValueProposition.new(:con => connection)
#one[:detail_url] = number_of_disks['url']
#one[:values] = ['1', '2', '3', '4', '5', '6']
#one.save
#
## LINK THE DETAILS
## CDS
#  entities[:CDs].link_detail title_detail
#  entities[:CDs].link_detail date_detail
#  entities[:CDs].link_detail number_of_disks
#  entities[:CDs].link_detail notes_detail
#
#  # Artists
#  entities[:Artists].link_detail name_detail
#  entities[:Artists].link_detail notes_detail
#  entities[:Artists].link_detail birthday_detail
#  
#  #Tracks
#  entities[:Tracks].link_detail title_detail
#  entities[:Tracks].link_detail length_detail
#  
#  # Relation types
#  type_one = 'http://localhost:3000/relation_side_types/1.json'
#  type_many = 'http://localhost:3000/relation_side_types/2.json'
#  
#  # Link CD with aritis
#  cd_author_relation = Dedomenon::Relation.new(:con => connection)
#  cd_author_relation[:parent_url] = entities[:Artists] ['url']
#  cd_author_relation[:child_url] = entities[:CDs] ['url']
#  cd_author_relation[:parent_side_type_url] = type_many
#  cd_author_relation[:child_side_type_url] = type_many
#  cd_author_relation[:from_parent_to_child_name] = 'singer on'
#  cd_author_relation[:from_child_to_parent_name] = 'sung by'
#  cd_author_relation.save
#  
#  # Link CD with Tracks
#  cd_track_relation = Dedomenon::Relation.new(:con => connection)
#  cd_track_relation[:parent_url] = entities[:CDs] ['url']
#  cd_track_relation[:child_url] = entities[:Tracks] ['url']
#  cd_track_relation[:parent_side_type_url] = type_one
#  cd_track_relation[:child_side_type_url] = type_many
#  cd_track_relation[:from_parent_to_child_name] = 'contains'
#  cd_track_relation[:from_child_to_parent_name] = 'is on'
#  cd_track_relation.save
#  
#
#  
#   cd_instances={}
#
#    [
#      { :title => "Boris", :date => "1996-05-01", :disks => one, :notes =>"This is a psychedelic CD narrating the story of Boris, with different adventures he lives, likes the travel in space or in a black box"},
#      { :title => "Ray of light", :date => "1997-05-01", :disks => one},
#      { :title => "23 siempre", :date => "2003-10-01", :disks => one, :notes =>"First CD of the winner of Pop Idol in France."},
#      { :title => "The presidents of USA", :date => "1995-10-01", :disks => one, :notes =>"Really good man. Hilarous lyrics!"},
#      { :title => "The presidents of USA II", :date => "1998-10-01", :disks => one, :notes =>"As good as their first CD!"},
#      { :title => "Black or white", :date => "1992-05-01", :disks => one},
#      { :title => "Patience", :date => "2004-01-01", :disks => one, :notes=>"http://www.google.be/"},
#      { :title => "Kylie", :date => "1988-01-01", :disks => one, :notes=>"http://www.freedb.org/freedb_search_fmt.php?cat=misc&id=8a084c0a"},
#      { :title => "Songs in a minor", :disks => one, :notes=>"http://www.freedb.org/freedb_search_fmt.php?cat=rock&id=e40ff311"},
#      { :title => "Simply the truth", :disks => one, :notes=>"http://www.freedb.org/freedb_search_fmt.php?cat=blues&id=e710b510"},
#      { :title => "Forever gold", :disks => one, :notes=>"http://www.freedb.org/freedb_search_fmt.php?cat=jazz&id=d50b7510"},
#      { :title => "bon jovi", :disks => one, :notes=>"http://www.freedb.org/freedb_search_fmt.php?cat=rock&id=5308f909"},
#      { :title => "Purple rain", :disks => one, :notes=>"http://www.freedb.org/freedb_search_fmt.php?cat=misc&id=740a4809"},
#      { :title => "Marcher dans le sable", :disks => one, :notes=>"http://www.freedb.org/freedb_search_fmt.php?cat=rock&id=a809e90c"},
#      { :title => "Non homologué", :disks => one, :notes=>"http://www.freedb.org/freedb_search_fmt.php?cat=misc&id=a30b680b"},
#      { :title => "Double jeu", :disks => one, :notes=>"http://www.freedb.org/freedb_search_fmt.php?cat=misc&id=6a0b6d0a"},
#      { :title => "A contre jour", :disks => one, :notes=>"http://www.freedb.org/freedb_search_fmt.php?cat=blues&id=9b0a7f0b"},
#      { :title => "One million dollars hotel", :disks => one, :notes=>"<a href=\"http://www.freedb.org/freedb_search_fmt.php?cat=classical&id=da0d0e10\">test</A>"},
#      { :title => "music", :disks => one},
#      { :title => "something to remember", :disks => one},
#      { :title => "bedtime stories", :disks => one},
#    ].each do |cd|
#      cd_instance = Dedomenon::Instance.new(:con => connection)
#
#      cd_instance[:entity_url] = entities[:CDs]['url']
#      
#      cd_instance[:Title] = [cd[:title]] if cd[:title]
#      cd_instance[:Year] = [cd[:date]] if cd[:date]
#      cd_instance[:Number_of_Disks] = [cd[:disks]['value']] if cd[:disks]
#      cd_instance[:Notes] = [cd[:notes]] if cd[:notes]
#      cd_instance.save
#      cd_instances[cd[:title].downcase] = cd_instance
#
#    end
#    
#      artist_instances = {}
#      [
#        { :name => "Madonna" },
#        { :name => "The presidents of USA" },
#        { :name => "Gérald de Palma" },
#        { :name => "François Feldman" },
#        { :name => "U2" },
#        { :name => "Boris" },
#        { :name => "Jean-Jacques Goldman" },
#        { :name => "Alicia Keys" },
#        { :name => "Prince" },
#        { :name => "Michael Jackson" },
#        { :name => "Georges Michael" },
#        { :name => "Michel Berger" },
#        { :name => "France Gall" },
#        { :name => "Clouseau" },
#        { :name => "Axelle Red" },
#        { :name => "Kate Bush" },
#        { :name => "Blur" },
#        { :name => "Oasis" },
#        { :name => "Robbie Willians" },
#        { :name => "Basement Jaxx" },
#        { :name => "John Lennon" },
#        { :name => "Paul McCartney" },
#        { :name => "The Beatles" },
#        { :name => "Sheila" },
#        { :name => "Demis Roussos" },
#        { :name => "Stevie Wonder" },
#        { :name => "Elvis Presley" },
#        { :name => "John Lee Hooker" },
#        { :name => "Eurythmics" },
#        { :name => "Vaya con dios" },
#        { :name => "Ricky Martin" },
#        { :name => "Georges Brassens" },
#        { :name => "Georges Moustaki" },
#        { :name => "Maria Calas" },
#        { :name => "Annie Cordi" },
#        { :name => "Nana Mouskouri" },
#        { :name => "Les gauf au suc" },
#        { :name => "The cardigans" },
#        { :name => "The Corrs" },
#        { :name => "Sttellla" },
#        { :name => "Genesis" },
#        { :name => "Alanis Morissette" },
#        { :name => "Peter Gabriel" },
#        { :name => "Johnny Halliday" },
#        { :name => "Beach Boys" },
#        { :name => "Bee gees" },
#        { :name => "Frank Sinatra" },
#        { :name => "Pow wow" },
#        { :name => "Anouk" },
#        { :name => "Wham" },
#        { :name => "Europe" },
#        { :name => "Garbage" },
#        { :name => "Guns & Roses" },
#        { :name => "TLC" },
#        { :name => "Julio Iglesias" },
#        { :name => "Toto Cotunio" },
#        { :name => "Johnny Logan" },
#        { :name => "Pixies" },
#        { :name => "The Ramones" },
#        { :name => "Iron Maiden" },
#        { :name => "Black Sabbath" },
#        { :name => "Metallica" },
#        { :name => "Nirvana" },
#        { :name => "Kylie Minogue" },
#        { :name => "Raphael" },
#        { :name => "Indochine" },
#        { :name => "Elton John" },
#        { :name => "Jenifer Lopez" },
#        { :name => "Eagle Eye Cherry" },
#        { :name => "Justin Timberlake" },
#        { :name => "N'sync" },
#        { :name => "Back stree boys" },
#        { :name => "Simply red" },
#        { :name => "Simple minds" },
#        { :name => "The cure" },
#        { :name => "Toto" },
#        { :name => "Black eye peas" },
#        { :name => "Pink" },
#        { :name => "Bony Tyler" },
#        { :name => "Eros Ramazotti" },
#        { :name => "Claude Barzotti" },
#        { :name => "Adamo" },
#        { :name => "Lio" },
#        { :name => "Plastic Bertranc" },
#        { :name => "Apollo 440" },
#        { :name => "UB40" },
#        { :name => "Front 242" },
#        { :name => "Claude François" },
#        { :name => "No doubt" },
#        { :name => "Texas" },
#        { :name => "Aha" },
#        { :name => "Boy George" },
#        { :name => "Culture club" },
#        { :name => "ZZ Top" },
#        { :name => "Ronan Keating" },
#        { :name => "Richard Gotainer" },
#        { :name => "Alain Chamfort" },
#        { :name => "Jamiroquai" },
#        { :name => "Serge Lama" },
#        { :name => "Francis Cabrel" },
#        { :name => "Ella Fitzerald" },
#      ].each  do |a|
#        artist_instance = Dedomenon::Instance.new(:con => connection)
#        artist_instance[:entity_url] = entities[:Artists]['url']
#        artist_instance[:Name] = [a[:name]]
#        artist_instance[:Notes] = [a[:notes]] if a[:notes]
#        artist_instance[:Birthday] = [a[:birthday]] if a[:birthday]
#        artist_instance.save
#        artist_instances[a[:name].downcase] = artist_instance
#        
#      end
#      
##  # Create the links
#
#      [
#        [ "madonna", "ray of light"],
#        [ "madonna", "music"],
#        [ "madonna", "bedtime stories"],
#        [ "madonna", "something to remember"],
#        [ "the presidents of usa", "the presidents of usa"],
#        [ "the presidents of usa", "the presidents of usa ii"],
#        [ "boris", "boris"],
#        [ "michael jackson", "black or white"],
#        [ "georges michael", "patience"],
#        [ "kylie minogue", "kylie"],
#        [ "bon jovi", "bon jovi"],
#        [ "john lee hooker", "simply the truth"],
#        [ "ella fitzerald", "forever gold"],
#        [ "prince", "purple rain"],
#        [ "gérald de palma","marcher dans le sable"],
#        [ "jean-jacques goldman","non homologué"],
#        [ "michel berger","double jeu"],
#        [ "france gall","double jeu"],
#        [ "françois feldman","a contre jour"],
#        [ "alicia keys","songs in a minor"],
#      ]. each do |l|
#        link = Dedomenon::Link.new(:con => connection)
#        artist = l[0].strip
#        cd = l[1].strip
#        puts "WARNGIN: Aritst #{artist} Not Found!"; next  if !artist_instances[artist]
#        puts "WARNGIN: CD #{cd} Not Found!"; next if !cd_instances[cd]
#        link[:relation_url] = cd_author_relation['url']
#        link[:parent_url] = artist_instances[artist]['url']
#        link[:child_url] = cd_instances[cd]['url']
#        link.save
#      end
#      
#      albums_dir = %Q(albums)
#      Dir.foreach(albums_dir) do |f|
#        title = f.sub(".csv","").gsub("_"," ")
#        next if [".",".."].include? f
#        CSV.open(albums_dir+"/"+f,"r") do |row|
#          next if row.length<3
#          #track_instance= Instance.new :entity => entities["tracks"]
#          track_instance = Dedomenon::Instance.new(:con => connection)
#          track_instance[:entity_url] = entities[:Tracks]['url']
#          track_instance[:Title] = [row[2]]
#          track_instance[:Length] = [row[1]]
#          track_instance.save
#
#          link = Dedomenon::Link.new(:con => connection)
#          link[:relation_url] = cd_track_relation['url']
#          link[:parent_url] = cd_instances[title]
#          link[:child_url] = track_instance['url']
#          link.save
#        end
#
#
#      end
#
#  
#  
#  
#  
#
#  
#  
#end
#
#conn = Dedomenon::Connection.new('mohsinhijazee@zeropoint.it', 'mohsinali.')
#
#
#
#create_databases(conn)




