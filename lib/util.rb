

module OMDB
  module Util
    def benchmark(msg)
      start = Time.now
      yield
      time = Time.now - start
      @logger.info sprintf(msg, time)
    end
  end
end
