Gem::Specification.new do |s|
  s.name        = 'fix_engine'
  s.version     = '0.0.1'
  s.date        = '2012-09-19'
  s.summary     = "Fix Engine is a (minimalistic) implementation of the Financial Information eXchange (fix protocol)"
  s.description = "Fix Engine is a (minimalistic) implementation of the Financial Information eXchange with client-server multithread workarounds (based on pr-fix: https://github.com/uritu/pr-fix, by Joseph Dunn <joseph@magnesium.net> )."
  s.authors     = ["Ivan Sidarau"]
  s.email       = 'ivan.sidarau@gmail.com'
  s.files       = [
				"lib/etc/COPYRIGHT.xml", "lib/etc/FIX40.xml", "lib/etc/FIX41.xml", "lib/etc/FIX42.xml", "lib/etc/FIX43.xml", "lib/etc/FIX44.xml", 
				"lib/fix_message.rb", "lib/fix_engine.rb", "lib/fix_response.rb", "lib/fix_session.rb" ]
  s.homepage    = 'http://github.com/sidorovis/fix_engine'
end