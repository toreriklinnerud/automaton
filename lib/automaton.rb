require 'ruby_extensions'
require 'latex'
require 'layout'
require 'set'

# Author::    Tor Erik Linnerud  (tel@jklm.no)
# Author::    Tom Gundersen  (teg@jklm.no)
# Copyright:: Copyright (c) 2008 JKLM DA
# License::   MIT
class Automaton
  
  attr_reader :start, :finals, :graph, :alphabet
  
  
  # Create a new automaton. new is intended for internal use. 
  # create makes it easier to create an automaton from scratch.
  # start - A symbol
  # finals - A set of symbols
  # graph - A transition function (Graph) which can be created like this:
  #     Automaton.new(:a, Set[:c], Graph.from_hash(:a => {'1' => Set[:b]}, :b => {'2' => Set[:a, :c]}))
  # This is interpreted as an Automaton with start state a, final (accepting) states :c, 
  # a transition from :a to :b on the letter 1 and a transition from :b to :a and :c on the letter 2.
  def initialize(start, finals, graph)
    raise ArgumentError, 'Invalid transition function' unless graph.is_a?(Graph)
    @start = start 
    @finals = finals
    @graph = graph
    @alphabet = graph.values.map{|transitions| transitions.keys}.flatten.to_set
  end
  
  # Create a new automaton, intended for public use
  # Unlike new, create allows you to use a single element instead of an array when you just have a single element. Furthermore, 
  # graph can be (and must be) a hash, instead of a Graph.
  # Instead of
  #     Automaton.new(:a, Set[:c], Graph.from_hash(:a => {'1' => [:b]}, :b => {'2' => [:a, :c]}))
  # you can now simply do
  #     Automaton.create(:a, :c, :a => {'1' => :b}, :b => {'2' => :c})
  def self.create(start, finals, graph)
    raise ArgumentError, "finals shouldn't be passed to create as a set" if finals.is_a?(Set)
    nfa_graph = graph.value_map do |state, transitions|
      transitions.value_map {|symbol, s| [s].flatten}
    end
    self.new(start, [finals].flatten.to_set, Graph.from_hash(nfa_graph)).prune
  end
  
  # Keep only reachable states. (Removes all unreachable states.)
  def prune
    reachable_states_cache = reachable_states
    finals = self.finals & reachable_states_cache
    graph = self.graph.prune(reachable_states_cache)
    self.class.new(start, finals, graph)
  end
  
  # Automaton accepting the complement of the language accepted by self
  def complement
    self.class.new(start, reachable_states - finals, graph)
  end
  
  # States reachable from the start state (default), or any other given state
  def reachable_states(from = start, already_seen = Set.new)
    new_states = (successors_of(from) - already_seen - [from])
    already_seen = already_seen + new_states + [from]
    new_states.inject(Set.new){|reachables, state| reachables + reachable_states(state, already_seen)} + [from]
  end
  
  # States reachable from state in one sucession
  def successors_of(state)
    state_transitions = graph[state]
    return [] unless state_transitions
    state_transitions.values.inject(Set.new){|reachables, states| reachables + states}
  end
  
  # Will the Automaton accept any string at all?
  def accepting?
    !(reachable_states & finals).empty?
  end
  
  # New automaton with each state tagged with the given name
  def tag(name)
    tagged_finals = finals.map{|state| state.tag(name)}.to_set
    tagged_graph = graph.key_value_map  do |state, transitions|
      tagged_transitions = transitions.value_map do |symbol, states|
        states.map{|s| s.tag(name)}.to_set
      end
      [state.tag(name), tagged_transitions]
    end
    self.class.new(start.tag(name), tagged_finals, tagged_graph)
  end

  def ==(other)
    start == other.start &&
      finals == other.finals &&
      graph == other.graph
  end
  
  # Create the intersection of two automata, which is basically the cartesian product of the two
  def intersect(other)
    start = self.start + other.start
    finals = self.finals.to_a.product(other.finals.to_a).map{|a,b| a + b}.to_set
    product = self.graph.product(other.graph)
    graph = product.key_value_map do |(state1, state2), (transitions1, transitions2)|
      common_symbols = transitions1.keys & transitions2.keys
      transitions = common_symbols.map do |symbol|
        states = transitions1[symbol].to_a.product(transitions2[symbol].to_a).map{|a, b| a + b}
        [symbol, states]
      end.to_h
      [state1 + state2, transitions]
    end
    self.class.new(start, finals, graph).prune
  end
  
  # Automaton accepting the language accepted by self minus the language accepted by other
  def -(other)
    alphabet = self.alphabet + other.alphabet
    self.intersect(other.to_total(alphabet).complement)
  end
  
  # self.language subset of other.language?
  def subset?(other)
    !(self - other).accepting?
  end
  
  # self.language == other.language?
  def accepting_same_language_as?(other)
    self.subset?(other) &&
      other.subset?(self)
  end
  
  # Set of transitions in the Automaton
  def transitions
    graph.map do |from, transitions|
      transitions.map do |label, to|
        to.map do |to|
          Transition.new(from, to, label)
        end
      end
    end.flatten
  end
  
  # New automaton which is the total version of self. This means that all states have a transition for every symbol in the alphabet.
  def to_total(alphabet)
    raise ArgumentError unless alphabet.is_a?(Set)
    all_states = Graph.from_hash((reachable_states + [:x]).map{|state| [state, {}]}.to_h)
    total_graph = all_states.merge(graph).value_map do |state, transitions|
      missing_symbols = (alphabet - transitions.keys.to_set)
      missing_transitions = missing_symbols.map{|symbol| [symbol, [:x]]}.to_h
      transitions.merge(missing_transitions)
    end
    self.class.new(start, finals, total_graph).prune
  end
  
  # Image of the Automaton in the form of a string of latex
  def to_tex
    nodes = reachable_states.each_with_index.map{|state, i| [state, Layout::Node.new(state, rand * i , rand * i)]}.to_h
    transitions.each do |transition|
        nodes[transition.from].connect(nodes[transition.to])
    end
    nodes.values.each do |node|
      node.position *= 2.5
    end
    layout = Layout.new(*nodes.values)
    layout.force_direct
    layout.normalize
    Latex.new(start, finals, nodes.values, transitions)
  end

  Transition = Struct.new(:from, :to, :label)
  
  
  class Graph < Hash
  
    # Create from hash
    def self.from_hash(hash)
      # Change from storing the states as an array to a set
      self.new.replace(hash.value_map do |state,transitions|
          transitions.value_map do |symbol,states|
            states.to_set
          end
        end)
    end
  
    # Creates a new hash where the new keys are the cartesian product of 
    # the keys of the old hashes and the new values the pair of values created by 
    # self.values_at(new_key.first), other.values_at(new_key.last)
    #     {:a => 1, :b => 2}.product(:c => 3, :d => 4)
    #     #=>    {[:a, :d] => [1, 4], [:a, :c] => [1, 3], [:b, :c] => [2, 3], [:b, :d] => [2, 4]}
    def product(other)
      self.keys.product(other.keys).inject(self.class.new) do |hash, (key1, key2)|
        hash[[key1,key2]] = [self[key1],other[key2]]
        hash
      end
    end
  
    # Invokes block once for each element of self, each time yielding key and value.
    # Creates a new hash from the key => value pairs returned by the block, 
    # these pairs should be an array of the form [key, value].
    #
    #     {:a => 1, :b => 2}.key_value_map{|key, value| [key.to_s, value * 2]}
    #     #=>   {"a" => 2, "b" => 4}
    def key_value_map
      self.inject(self.class.new) do |hash, (key,value)|
        new_key, new_value = yield(key, value)
        hash[new_key] = new_value
        hash
      end
    end
  
    def [](state)
      return super || {}
    end
  
    def to_hash
      Hash.new.replace(self)
    end
  
    def merge(other)
      raise ArgumentError, 'Merging with something that is not a TransitionFunction' unless other.is_a?(Graph)
      new = {}
      self.each do |state, transitions|
        new[state] = Graph.merge_transitions(other[state],transitions)
      end
      other.each do |state, transitions|
        new[state] = transitions unless new.has_key?(state)
      end
      Graph.from_hash(new)
    end
  
    def self.merge_transitions(t1,t2)
      new = {}
      t1.each do |symbol,states|
        new[symbol] = (states + (t2[symbol] || Set.new))
      end
      t2.merge(new)
    end
  
    def prune(reachable_states)
      pruned = self.select do |state,_|
        reachable_states.include? state
      end.to_h
      Graph.from_hash(pruned)
    end
  end
end