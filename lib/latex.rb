# Author::    Tor Erik Linnerud  (tel@jklm.no)
# Copyright:: Copyright (c) 2008 JKLM DA
# License::   MIT

require 'rtex'
require 'fileutils'

class Automaton
  # Latex representation of an Automaton
  class Latex
    def initialize(initial, finals, states, transitions)
      @initial = Initial.new(initial)
      @finals = finals.map{|final| Final.new(final)}
      @states = states.map{|state| State.new(*state.to_a)}
      @transitions = transitions.map{|transition| Transition.new(*transition.to_a)}
    end
   
    def render_pdf(file_path)
      target_path = File.expand_path(file_path)
      our_path = File.expand_path(File.dirname(__FILE__))
      ENV['TEXINPUTS'] = ".:#{our_path}/tex:"
      template = File.read("#{our_path}/tex/template.tex")
      doc = RTeX::Document.new(template, :processor => 'tex2pdf')
      doc.to_pdf(binding) do |tempfile_path|
        FileUtils.mv tempfile_path, target_path
      end
    end
    
    def values
      [@initial, @finals, @states, @transitions]
    end
    
    def ==(other)
      self.values == other.values
    end
    
    Initial = Struct.new(:name) do 
      def to_s
         "\\Initial{#{name}}"
      end
    end
    
    State = Struct.new(:name, :x, :y) do 
      def to_s
        "\\State[%s]{(%.2f, %.2f)}{#{name}}" % self.to_a
      end
    end
    
    Transition = Struct.new(:from, :to, :label) do 
      def to_s
        "\\EdgeL{#{from}}{#{to}}{#{label}}"
      end
    end
    
    Final = Struct.new(:name) do 
      def to_s
        "\\Final{#{name}}"
      end
    end
  end
end
