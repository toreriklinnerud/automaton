require File.dirname(__FILE__) + '/spec_helper.rb'
require 'layout'

Node = Automaton::Layout::Node
describe Automaton::Layout do
  before(:all) do
    @a = Node.new(:a, 0, 0)
    @b = Node.new(:b, 0, 1)
    @c = Node.new(:c, 16, 0)
    @a.connect(@b, @c)
  end

  it "does force direction" do
    graph = Automaton::Layout.new(@a, @b, @c)
    graph.nodes.size.should == 3
    graph.force_direct
    graph.normalize
    graph.nodes.size.should == 3
  end

  describe Automaton::Layout::Node do 

    before(:all) do
      @a = Node.new(:a, 0, 0)
      @b = Node.new(:b, 0, 1)
      @c = Node.new(:c, 4, 0)
      @a.connect(@b, @c)
    end
    
    it "has repulsion" do 
      @a.repulsion(@b).should be_close_to_enum(Vector[0, 0.23], 0.01)
      @a.repulsion(@c).should == -@c.repulsion(@a)
      @a.repulsion(@c).should be_close_to_enum(Vector[0.0149, 0], 0.01)
    end
    
    it "has attraction" do
      @a.attraction(@b).should be_close_to_enum(Vector[0,  -0.8], 0.01)
      @a.attraction(@c).should be_close_to_enum(Vector[0.4, 0], 0.01)
      @a.attraction(@c).should == -@c.attraction(@a)
      @b.attraction(@c).should be_close_to_enum(Vector[0, 0], 0.01)
    end

    it "has vector to other node" do 
      @a.vector(@b).should be_close_to_enum(Vector[0.0, 1.0])
      @a.vector(@c).should be_close_to_enum(Vector[4.0, 0.0])
    end
  end
end
