require File.dirname(__FILE__) + '/spec_helper.rb'
require 'automaton'

describe Automaton do
 
  def example(*args, &block)
    @a ||= Automaton.build(*args, &block)
  end
  
  def expected(*args, &block)
    @e ||= Automaton.build(*args, &block)
  end

  it "can be pruned" do
    example(:a, :b) do 
      a('1' => :b, 
        '2' => :d)
      c('3' => :b)
    end
      
    expected(:a, :b) do
      a('1' => :b, '2' => :d)
    end
    
    example.prune.should == expected
  end
  
  it "has successors" do
    example(:a, :b) do
      a('1' => [:b, :c], 
        '2' => :d)
      c('3' => :b)
    end
    
    example.successors_of(:a).should == Set[:b, :c, :d]
    example.successors_of(:b).should == Set[]
    example.successors_of(:c).should == Set[:b]
  end
  
  it "has start state and final states" do
    example(:a, :b) do 
      a('1' => [:b, :c], '2' => :d)
      c('3' => :b)
    end
    
    example.start.should == :a
    example.finals.should == Set[:b]
  end
  
  it "is comparable" do
    example(:a, :b) { a('1' => :b) }
    expected(:a, :b){ a('1' => :b) }
    example.should == expected
  end
  
  it "is taggable" do
    automata = Automaton.create(:a, :b, :a => {'1' => [:b, :c]})
    automata.tag(:left).should == Automaton.create(:a_left, [:b_left], :a_left => {'1' => [:b_left, :c_left]})
  end
  
  it "has reachable states" do
    automata = Automaton.create(:a, :b, {:a => {'1' => [:b, :c], '2' => [:d]}, :x => {'3' => [:a]}})
    automata.reachable_states.should == Set[:a, :b, :c, :d]
  end
  
  it "can deal with loops on reachable states" do
    automata = Automaton.create(:a, :x, {:a => {'1' => [:b]}, :b => {'1' => [:a]}})
    automata.reachable_states.should == Set[:a, :b]
  end
  
  it "has an alphabet" do 
    automata = Automaton.create(:a, :b, :a => {'1' => :b, '2' => :x}, 
    :b => {'1' => :x, '2' => :c}, 
    :x => {'1' => :x, '2' => :x})
    automata.alphabet.should == Set['1', '2']
  end
  
  it "has transitions" do 
    pending
    automaton = Automaton.create(:a, :b, :a => {'1' => [:b, :c], '2' => [:d]}, :b => {'3' => [:f]})
    one = Automaton::Transition.new(:a, Set[:b, :c], '1')
    two = Automaton::Transition.new(:a, Set[:d], '2')
    three = Automaton::Transition.new(:b, Set[:f], '3')
    automaton.transitions.to_set.should == Set[one, two, three]
  end
  
  it "may not accept any strings" do
    Automaton.create(:a, [:b], :a => {'1' => :b}).should be_accepting
    Automaton.create(:a, [], :a => {'1' => :b}).should_not be_accepting
    Automaton.create(:a, [:b], :a => {'1' =>:c}).should_not be_accepting
  end
  
  it "has a complement" do
    automata = Automaton.create(:a, :b, {:a => {'1' => [:b, :c], '2' => [:d]}, :c => {'3' => [:b]}})
    automata.complement.complement.should == automata
    automata.complement.finals.should == Set[:a,:c,:d]
  end
  
  it "has intersection for total DFA" do
    one = Automaton.create(:a, :b, :a => {'1' => :b, '2' => :a}, :b => {'1' => :b, '2' => :b})
    two = Automaton.create(:x, [:x, :y], :x => {'1' => :y, '2' => :x}, :y => {'1' => :x, '2' => :y})
    product = Automaton.create(:a_x, [:b_x, :b_y], :a_x => {'1' => :b_y, '2' => :a_x},
                                              :b_x => {'1' => :b_y, '2' => :b_x},
                                              :b_y => {'1' => :b_x, '2' => :b_y})
    one.intersect(two).should == product
  end

  it "has intersection for NFA" do
    one = Automaton.create(:a, :b, :a => {'2' => :a}, :b => {'1' => :b, '2' => [:a,:b]})
    two = Automaton.create(:x, [:x, :y], :x => {'1' => :y, '2' => :x}, :y => {'1' => :x, '2' => :y})
    product = Automaton.create(:a_x, [:b_x, :b_y], :a_x => {'2' => :a_x},
                                              :a_y => {'2' => :a_y},
                                              :b_x => {'1' => :b_y, '2' => [:a_x,:b_x]},
                                              :b_y => {'1' => :b_x, '2' => [:a_y,:b_y]})
    one.intersect(two).should == product
  end
  
  it "subtracts another automata from itself" do
    one = Automaton.create(:a, [:b], :a => {'1' => [:b]})
    one_two = Automaton.create(:a, [:b, :c], {:a => {'1' => :b, '2' => :c}})
     (one_two - one).should be_accepting
     (one - one_two).should_not be_accepting
     (one - one).should_not be_accepting
  end
 
  it "can be made total" do
    input = [:a, :b, {:a => {'1' => [:b,:c]}}]
    automata = Automaton.create(*input)
    total_automata = Automaton.create(:a, :b, :a => {'1' => [:b,:c], '2' => :x},
                                         :b => {'1' => :x, '2' => :x},
                                         :c => {'1' => :x, '2' => :x},
                                         :x => {'1' => :x, '2' => :x})
    automata.to_total(Set['1','2']).should == total_automata
    automata.to_total(Set['1','2']).to_total(Set['1','2']).should == automata.to_total(Set['1','2'])
  end
  
  it "is comparable to other automata" do
    a = Automaton.create(:a, [:b], :a => {'1' => :b})
    b = Automaton.create(:a, [:b], :a => {'2' => :b})
    a.should_not be_accepting_same_language_as(b)
    a.should be_accepting_same_language_as(a)

    a = Automaton.create(:a, [:b], :a => {'1' => :b})
    b = Automaton.create(:a, [:b], :a => {'1' => :b})
    a.should be_accepting_same_language_as(b)
    
  end
  
  it "determines if it accepts a subset of the lanugage of other automata" do
    small = Automaton.create(:a, [:b], {:a => {'1' => :b}})
    medium = Automaton.create(:a, [:b, :c], {:a => {'1' => :b}, :b => {'2' => :c}})
    large = Automaton.create(:a, [:b, :c], {:a => {'1' => :b, '2' => :c}, :b => {'1' => :c}})
    
    small.subset?(medium).should be_true
    small.subset?(large).should be_true
    large.subset?(large).should be_true
    medium.subset?(small).should be_false
    large.subset?(medium).should be_false
    small.subset?(small).should be_true
    medium.subset?(medium).should be_true
    large.subset?(large).should be_true
  end
  
  it "has a latex representation" do
    pending
    small = Automaton.create(:a, :b, :a => {'1' => :b})
    latex = Automaton::Latex.new(:a, [:b], [[:a, 0, 0], [:b, 1, 1]], [[:a, :b, '1']])
    small.to_tex.should == latex
  end
end

describe Automaton::Graph do
  
  it "allows a state to have no transitions" do
    tf = Automaton::Graph.new
    tf[:a].should == {}
    tf[:a]='b'
    tf[:a].should == 'b'
    hash = {:b => {'2' => Set[:c]}}
    Automaton::Graph.from_hash(hash)[:a].should_not == hash[:a]
    Automaton::Graph.from_hash(hash)[:b].should == hash[:b]
  end
  
  it "can merge two hashes of transitions" do
    t1 = {}
    t2 = {'1' => Set[:a]}
    Automaton::Graph.merge_transitions(t1,t2).should == t2
  end
  
  it "can merge in another transition function" do
    tf1 = Automaton::Graph.from_hash({:a => {'1' => [:a,:b]}})
    tf2 = Automaton::Graph.from_hash({:a => {'1' => [:a,:c]}})
    tf3 = Automaton::Graph.from_hash({:b => {'1' => [:a,:c]}})
    tf1.merge(tf1).should == tf1.merge(tf1)
    tf2.merge(tf2).should == tf2.merge(tf2)
    tf2.merge(tf1).should == tf1.merge(tf2)
    tf2.merge(tf3).should == Automaton::Graph.from_hash({:b => {'1' => [:a,:c]}, :a => {'1' => [:a,:c]}})
    tf1.merge(tf2).class.should == Automaton::Graph
  end

end
