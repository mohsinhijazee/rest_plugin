# Set the RAILS_ENV to test so that when rails is loaded, its with test mode
ENV["RAILS_ENV"] = "test"
# Load the Rails so that we can access all the libraries.

require File.expand_path(File.dirname(__FILE__) +  "/../../../../config/environment")
require 'test_help'


class Test::Unit::TestCase
  # Turn off transactional fixtures if you're working with MyISAM tables in MySQL
  self.use_transactional_fixtures = true
  
  # Instantiated fixtures are slow, but give you @david where you otherwise would need people(:david)
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
  
  
  # *Description*
  # This method takes an active reocrd model, and a hash that represents same
  # obejcts with its fields. it checks if both are same or not.
  #

  def assert_similar(model, hash, to_skip = [])
    hash = JSON.parse(hash) if hash.is_a? String
    to_skip.collect! {|attr| attr.to_s}

    # Remove the root element!
    if hash.keys.length == 1
      hash = hash[hash.keys[0]]
    end
    assert model, "assert_same: Model is nil!"
    assert hash,  "assert_same: Hash is nil!"
    assert model.is_a?(ActiveRecord::Base), "assert_same: Model is not an ActiveReocrd object!"
    assert hash.is_a?(Hash), "assert_same: Model is not a Hash!"
    
    # For each of the attributes:
    model.attributes.each do |attr, value|

      # skip date and time things for now
      if hash.has_key? attr
        next if to_skip.include? attr.to_s
        hash[attr] = value.class.parse hash[attr] if [Date, DateTime, Time].include? value.class
        assert_equal value, hash[attr], "#{model.class.name}##{attr} differs!" if hash.has_key?(attr)
      end

    end
    
  end
  
end
