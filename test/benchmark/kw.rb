require "test_helper"

gem "benchmark-ips"
require "benchmark/ips"

=begin
# Learning

Don't use doublesplat when you don't need it.

=end

def positional(first, kws)
end

def doublesplat(first, **kws)
end

#  positional:  7971762.3 i/s
# doublesplat:  4536817.7 i/s - 1.76x  slower


first, kws = 1, {}

Benchmark.ips do |x|
  x.report("positional") { positional(first, kws) }
  x.report("doublesplat") { doublesplat(first, kws) }

  x.compare!
end


