# Various monkeypatching

class Array
  # Turns an array of the form [[key, value], ...] into a hash of the form {key => value }
  #     [[:a, 1], [:b, 2]].to_h    #=> {a => 1, :b => 2}
  def to_h
    inject({}) { |m, e| m[e[0]] = e[1]; m }
  end
end

class Symbol
  # Create a new symbol with _name added
  def tag(name)
    "#{self}_#{name}".to_sym
  end
  
  # Create a new symbol a_b from the symbol a and b
  def +(other)
    "#{self}_#{other}".to_sym
  end
end

class Hash  
  # Invokes block once for each pair of self, each time yielding a new key, value pair.
  # Returns a new hash with the values of the original hash replaced by those returned from the block.
  #
  #     {:a => 1, :b => 2}.key_value_map{|key, value| value * 2}
  #     #=>    {:a => 2, :a => 4}
  def value_map
    self.inject(self.class.new) do |hash, (key,value)|
      hash[key] = yield(key, value)
      hash
    end
  end
end