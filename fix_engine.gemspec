lib_rb_files = Dir.glob( File.join( "lib", "**", "*.rb") )
lib_etc_files = Dir.glob( File.join( "lib/fix_engine/etc", "**", "*.xml") )
test_rb_files = Dir.glob( File.join( "test", "**", "*.rb") )
examples_rb_files = Dir.glob( File.join( "examples", "**", "*.rb") )
puts lib_rb_files + test_rb_files + lib_etc_files + examples_rb_files + ["Rakefile"]
Gem::Specification.new do |s|
  s.name        = 'fix_engine'
  s.version     = '0.0.4'
  s.date        = '2012-10-04'
  s.summary     = "Fix Engine is a (minimalistic) implementation of the Financial Information eXchange (fix protocol)"
  s.description = "Fix Engine is a (minimalistic) implementation of the Financial Information eXchange with client-server multithread workarounds (based on pr-fix: https://github.com/uritu/pr-fix, by Joseph Dunn <joseph@magnesium.net> )."
  s.authors     = ["Ivan Sidarau"]
  s.email       = 'ivan.sidarau@gmail.com'
  s.files       = lib_rb_files + test_rb_files + lib_etc_files + examples_rb_files + ["Rakefile"]
  s.homepage    = 'http://github.com/sidorovis/fix_engine'
end
