require 'rubygems'
require 'rspec/core/rake_task'
require 'jasmine'
load 'jasmine/tasks/jasmine.rake'

desc 'Default: run all specs.'
task :default => :ci

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  # Put spec opts in a file named .rspec in root
end

desc "Run the CI test suite"
task :ci => [:spec, 'jasmine:ci']

namespace :bookmarklet do
	task :combine do
		contents = Dir["bookmarklet/*.js"].map { |f| File.read(f) }.join("\n")
		File.open('bookmarklet.js', 'w') do |f|
			f << File.read('bookmarklet/build/build_header.js')
			f << contents
			f << File.read('bookmarklet/build/build_footer.js')
		end
	end

	task :compress do
		require 'closure-compiler'
		combined_file = File.open('bookmarklet.js', 'r')
		File.open('bookmarklet.min.js', 'w') do |f|
			f << Closure::Compiler.new.compile(combined_file)
		end
	end

	desc "Build the bookmarklet files."
	task :build => [:combine, :compress]
end
