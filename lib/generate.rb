require 'node'

Node = Automaton::Layout::Node

a = Node.new(:a, 0, 0)
b = Node.new(:b, 1, 0)
c = Node.new(:c, 2, 0)
d = Node.new(:d, 2, 2)

nodes = [a, b, c, d]
b.connect(a, c, d)

graph = Automaton::Layout.new(*nodes)
graph.force_direct
graph.normalize



states = graph.nodes.map do |node|
  x, y = *(node.position * 2.5)
  "\\State[%s]{(%.2f, %.3f)}{%s}" % [node.name, x, y, node.name.to_s.upcase]
end

transitions = graph.nodes.map do |node|
  node.connections.map{|other| [node.name.to_s, other.name.to_s].sort}
end.flatten(1).uniq.map do |from, to|
  "\\EdgeL{#{from.upcase}}{#{to.upcase}}{#{from}-#{to}}"
end

initial = a.name.to_s.upcase
initial = "\\Initial{#{initial}}"
final = d.name.to_s.upcase
final = "\\Final{#{final}}"

puts transitions.inspect

string =  states.join(' ')
source = File.read('template.tex')
source.sub!('STATES', states.join("\n"))
source.sub!('TRANSITIONS', transitions.join("\n"))
source.sub!('INITIAL', initial)
source.sub!('FINAL', final)
File.open('automaton.tex', 'w'){|file| file.write(source)}
