require 'matrix'
require 'set'

# Author::    Tor Erik Linnerud  (tel@jklm.no)
# Copyright:: Copyright (c) 2008 JKLM DA
# License::   MIT

class Automaton
  class Layout

    SPRING_LENGTH = 1
    REPULSION = 5
    ATTRACTION = 1
    TIMESTEP = 0.5
    ENERGY_TRESHOLD = 0.0001
    DAMPING = 0.75
    
    attr_reader :nodes
    def initialize(*nodes)
      @nodes = nodes
    end
    
    def force_direct
      nodes.each{|node| node.velocity = Vector[0.0, 0.0]}
      total_kinetic_energy = 9999
      until total_kinetic_energy < ENERGY_TRESHOLD
        total_kinetic_energy = 0.0
        nodes.each do |node|
          net_force = (nodes - [node]).reduce(Vector[0, 0]) do |sum, other_node|
            sum += node.repulsion(other_node) + node.attraction(other_node)
          end
          node.velocity = (node.velocity + net_force * TIMESTEP) * DAMPING
          node.position += node.velocity * TIMESTEP
          total_kinetic_energy += node.speed**2
        end
      end
    end

    def normalize
      min_x = nodes.map{|node| node.x}.min
      min_y = nodes.map{|node| node.y}.min
      min = Vector[min_x - 1, min_y - 1]
      nodes.each{|node| node.position -= min}
    end

    def to_s
      nodes.map{|node| node.position}.inspect
    end
    
    class Node
      attr_reader :name
      attr_accessor :position, :velocity, :connections
      def initialize(name, x, y)
        @name = name
        @position = Vector[x, y]
        @velocity = Vector[0, 0]
        @connections = Set.new
      end

      def connect(*nodes)
        @connections = @connections | nodes.to_set
        @connections.each do |node|
          node.connect(self) unless node.connected?(self)
        end
      end

      def connected?(other)
        @connections.member?(other)
      end

      def repulsion(other)
        vector = vector(other)
        vector.unit * (1 / (4 * Math::PI * REPULSION * vector.r**2))
      end

      def attraction(other)
        return Vector[0, 0] unless connected?(other)
        vector = vector(other)
        vector.unit * -(ATTRACTION * (SPRING_LENGTH - vector.r.abs))
      end

      def vector(other)
        other.position - self.position
      end

      def speed
        velocity.r
      end
      
      def x
        position[0]
      end
      
      def y
        position[1]
      end
      
      def to_a
        puts "helllllo"
        [name, x, y]
      end
    end
  end
end

class Vector
  def unit
    self * (1 / self.r)
  end

  def -@
    self.map{|a| -a}
  end
end
