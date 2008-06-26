require 'rubygems'

Gem::manage_gems

require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
    s.platform  =   Gem::Platform::RUBY
    s.name      =   "automaton"
    s.version   =   "0.0.1"
    s.author    =   "Tor Erik Linnerud"
    s.email     =   "tel@jklm.no"
    s.summary   =   "Implementation of automata, supporting regular language operations"
    s.files     =   FileList['lib/*.rb', 'test/*'].to_a
    s.require_path  =   "lib"
    s.autorequire   =   "automaton"
    s.test_files = Dir.glob('tests/*.rb')
    s.has_rdoc  =   true
    s.extra_rdoc_files  =   ["README"]
end

Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
end

task :default => "pkg/#{spec.name}-#{spec.version}.gem" do
    puts "generated latest version"
end