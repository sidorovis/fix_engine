require 'rake/testtask'

Rake::TestTask.new do |t|
	t.libs << 'test'
	t.test_files = FileList['test/*/*.rb']
	t.verbose = false
end

desc "Run tests"
task :default => :test
