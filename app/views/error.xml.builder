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
    traces = @error.backtrace.split('\n')
    xml.backtrace do
      traces.each do |trace| 
        xml.t trace
      end
    end
  end
end