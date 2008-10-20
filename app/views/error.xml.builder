xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"

xml.error do
  xml.code @error.class.name
  xml.message h(@error.message)
  xml.reasons(:type => 'array') do
    @error.reasons.each do |reason|
      xml.reason reason
    end
  end
  # if development or test environment, dump backtrace also
  if %(development test).include? RAILS_ENV
    xml.backtrace @error.backtrace.to_s
  end
end