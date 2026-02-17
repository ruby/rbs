module RBS
  class RactorPool
    attr_reader :ractors
    attr_reader :worker_port
    attr_reader :result_port

    (STOP = Object.new).freeze

    def initialize(size, &block)
      @worker_port = Ractor::Port.new
      @result_port = Ractor::Port.new

      block = Ractor.shareable_proc(&block) # steep:ignore BlockTypeMismatch

      @ractors = size.times.map do
        Ractor.new(block, worker_port, result_port, STOP, name: "RBS::RactorPool(worker_ractor=#{_1})") do |block, worker_port, result_port, stop|
          worker_port << Ractor.current

          loop do
            task = Ractor.receive
            if stop.equal?(task)
              break
            else
              result = block[task]
              result_port.send(result)
              worker_port << Ractor.current
            end
          end
        end
      end

      # ObjectSpace.define_finalizer(self, RactorPool.finalizer(ractors))
    end

    def self.finalizer(ractors)
      ->(_) {
        ractors.each { _1 << RactorPool::STOP; _1.join }
      }
    end

    def map(objects)
      results = [] #: Array[untyped]

      each(objects) do |result|
        results << result
      end

      results
    end

    def each(objects, &block)
      count = objects.size

      thread = Thread.start do
        index = 0
        objects.each do |obj|
          ractor = worker_port.receive
          ractor.send(obj)
          index += 1
        end

        # ractors.each { _1 << RactorPool::STOP }
      end

      while count > 0
        yield result_port.receive
        count -= 1
      end

      thread.join()

      nil
    end

    def self.map(objects, size, &block)
      pool = RactorPool.new(size, &block)
      pool.map(objects)
    end
  end
end
