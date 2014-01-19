class Flexim
  attr_reader :objects

  def initialize(&blk)
    instance_exec(&blk)
  end
  
  alias_method :flexim_original_method_missing, :method_missing
  
  def method_missing(symbol, *args, &block)
    type = Flexim.known_types[symbol]
    if type
      @stack ||= []
      object = type.new
      putsd "new #{object}"
      
      if @stack.last
        fail "Cannot create #{type.name} inside #{@stack.last} (missing method '<<')" unless @stack.last.respond_to?(:<<)
        @stack.last << object
      else
        @objects ||= []
        @objects << object
      end
      
      @stack.push(object)
      instance_exec(&block)
      @stack.pop
    elsif @stack.last.respond_to? "#{symbol}="
      putsd "set #{symbol} to #{args.first}"
      @stack.last.send("#{symbol}=", *args)
    else
      flexim_original_method_missing(symbol, *args, &block)
    end
  end
  
  def include(type)
    fail unless @stack && @stack.last
    @stack.last.extend(type)
  end
  
  def this(&block)
    fail unless @stack && @stack.last
    @stack.last.instance_exec(&block)
  end
  
  def putsd(str)
    puts "#{' ' * @stack.count}#{str}" if Flexim.debug_mode?
  end
  
  def <<(object)
    @objects ||= []
    @objects << object
  end
  
  class << self
    attr_reader :known_types
  
    def debug_mode?
      return true
    end
  
    def <<(type)
      puts "new type '#{type.name}'" if debug_mode?
      @known_types ||= { entity: Object }
      @known_types[type.name.downcase.to_sym] = type
    end
  end
end

module Container
  attr_reader :objects
  
  def <<(object)
    @objects ||= []
    @objects << object
  end
end

#require 'entity'
Flexim << module Entity
  attr_accessor :name, :description
  self
end

#require 'screen'
Flexim << class Screen; self; end

#require 'energy'
Flexim << module Consumer
  attr_accessor :energy_source, :energy_consumption
  self
end

Flexim << class Generator
  attr_accessor :output
  self
end

Flexim << class Hub
  attr_accessor :energy_source
  
  
  
  self
end

#require 'room'
Flexim << class Room
  include Container
  include Entity
  self
end

vessel = Flexim.new {
  @warp_core = generator {
    output 100
  }

  @bridge = room {
    description "The bridge."
  
    @terminal = screen {
      include Consumer
      energy_source @warp_core
      energy_consumption 0.1
    }
  }
}

require 'pp'
pp vessel

