xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"

xml.error do
  xml.code @code
  xml.message h(@msg)
end