begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')


module EnumerableMatchers
  class BeCloseToEnum #:nodoc:
    def initialize(expected, delta)
      @expected = expected
      @delta = delta
    end
    
    def matches?(actual)
      @actual = actual
      return false if actual.nil?
      return false unless @actual.size == @expected.size
      @actual.to_a.zip(@expected.to_a).all? do |actual_item, expected_item|
        (actual_item - expected_item).abs < @delta
      end
    end
    
    def failure_message
        "expected #{@expected} +/- (< #{@delta}), got #{@actual}"
    end
    
    def description
        "be close to #{@expected} (within +- #{@delta})"
    end
  end
  
  
  def be_close_to_enum(expected, delta = 1.0e-014)
    BeCloseToEnum.new(expected, delta)
  end
end

Spec::Runner.configure do |config|
  config.include(EnumerableMatchers)
end
