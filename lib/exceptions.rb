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


# This module contains all the exception classes that our instance processor library
# uses for now. The instance processor library was specifically written for REST API
# as a low level interface to dedomenon. It is yet a bunch of methods only but
# later on, we will add a more object oriented and nice lower level API that is 
# accessible to both, the core application and any of the plugins such as this one.
# Our approach on exception handling is that we do not handle any exception in the
# codd and they're only catched at the most higher level where the actuation function
# is being called.
# The error would be like this:
#   * Code
#   * Message
#   * Reason
# The code would be mostly the name of the exception. This way, we would save
# ourselves of maintaining spearate error symbols. 
# The message is the exception message
# Reason is the reason for the error. This might be nil.
# 

# *Description*
#   This is the standard exception class. 
#     * code is the HTTP code to be returned to client
#     * reason is the optional reason why error occured. 
#       It is always an array of strings and might be empty but NOT Nil!
#
class MadbException < Exception
   attr_accessor :code
   attr_accessor :reasons
   
   def initialize(code, message = '' , reasons = [])
     super(message)
     @code = code
     if !reasons.is_a? Array
      @reasons = [reasons]
     else
       @reasons = reasons
     end
   end
 end
 
 # A resource was not found
 class ResourceNotFound < MadbException
   def initialize(message = '', reasons = [])
     super(404, message, reasons)
   end
 end
 
 # Resource being provided is not valid
 class BadResource < MadbException
   def initialize(message = '', reasons = [])
     super(400, message, reasons)
   end
 end
 
 class ObsoleteResource < MadbException
   def initialize(message = '', reasons = [])
     super 409, message, reasons
   end
 end
 
 # REST call contains conflicting parameters
 class ConflictingCall < MadbException
   def initialize(message = '', reasons = [])
     super(409, message, reasons)
   end
 end
 
 # An internal server error
 class InternalServerError < MadbException
   def initialize(message = '', reasons = [])
     super 500, message, reasons 
   end
 end
 
 # Cannot delete primary user
 class CantDeletePrimaryUser < MadbException
   def initialize(message = 'Cannot delete Primary User', reasons = [])
     super 403, message, reasons 
   end
 end
 
 
 
 # *Description*
 #    This method takes an exception, and decides what has occured.
 #    if its an exception drived from the MadbException class, then the 
 #    information is returned as this.
 #    But if its an ActiveRecord::RecordInvalidl kind of exception, then
 #    it would report the reasons also.
 #
 #
 def process_exception(exception)
   
   if exception.is_a? MadbException
     return exception
   elsif exception.is_a? ActiveRecord::RecordInvalid or exception.is_a? ActiveRecord::RecordNotSaved
     # Pick up the record and all the reasons for which it failed
     reasons = get_reasons(exception)
     e = BadResource.new(exception.message, reasons)
   elsif exception.is_a? ActiveRecord::StaleObjectError
     e = ObsoleteResource.new(exception.message)
   elsif exception.is_a? ActiveRecord::RecordNotFound
     e = ResourceNotFound.new(exception.message)
   else
     e = InternalServerError.new(exception.message)
   end
   
   e.set_backtrace(exception.backtrace)
   return e
   
   
 end
 
 
 # *Description*
 #   This function extracts the reasons if its an ative record object error
 #
 def get_reasons(exception)
   reasons = []
   # If its an exception that contains the record attribute to have errors
   # then list them down
   if exception.respond_to? :record
    if exception.record.errors.length > 0
      exception.record.errors.each do |field, reason|
        reasons << field.to_s + ': ' + reason.to_s
      end
    end
   else
     reasons << exception.message
   end
   
   return reasons
 end