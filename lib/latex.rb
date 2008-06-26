class Automaton
  class Latex
    def initialize(initial, finals, states, transitions)
      @initial = Initial.new(initial)
      @finals = finals.map{|final| Final.new(final)}
      @states = states.map{|state| State.new(*state.to_a)}
      @transitions = transitions.map{|transition| Transition.new(*transition.to_a)}
    end
   
    def to_s
      template = File.read('tex/template.tex')
      template.sub!('STATES', @states.join("\n"))
      template.sub!('TRANSITIONS', @transitions.join("\n"))
      template.sub!('INITIAL', @initial.to_s)
      template.sub!('FINAL', @finals.join("\n"))
      template
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
