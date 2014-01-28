require 'active_support/concern'
require 'pyramid/logging'

module Pyramid
  module Benchmark
    extend ActiveSupport::Concern

    def benchmark(description, &block)
      t1 = Time.now
      rv = yield
      t2 = Time.now
      elapsed = sprintf("%0.2f", (t2-t1)*1000)
      logger.info("#{description}: #{elapsed} ms")
      rv
    end
  end
end