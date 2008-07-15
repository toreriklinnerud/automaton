require 'rubygems'

Gem::manage_gems

require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
    s.platform  =   Gem::Platform::RUBY
    s.homepage  =   "http://www.jklm.no/automation"
    s.rubyforge_project = "automaton"
    s.name      =   "automaton"
    s.version   =   "0.0.1"
    s.author    =   "Tor Erik Linnerud"
    s.email     =   "tel@jklm.no"
    s.summary   =   "Implementation of automata, supporting visualization and regular language operations"
    s.files     =   FileList['lib/*.rb', 'lib/tex/*', 'spec/*',].to_a
    s.require_path  =   "lib"
    s.test_files = Dir.glob('spec/*_spec.rb')
    s.has_rdoc  =   true
    s.extra_rdoc_files  =   ["README"]
    s.add_dependency('rtex', '>= 2.0.0')
    s.executables = ['tex2pdf']
end

Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
end

task :default => "pkg/#{spec.name}-#{spec.version}.gem" do
    puts "generated latest version"
end