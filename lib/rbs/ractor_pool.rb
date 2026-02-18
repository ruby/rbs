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

          results = [] #: Array[untyped]

          loop do
            task = Ractor.receive
            if stop.equal?(task)
              break
            else
              task.each do |t|
                result = block[t]
                results << result
                worker_port << Ractor.current
              end
            end
          end

          results.freeze
        end
      end

      # ObjectSpace.define_finalizer(self, RactorPool.finalizer(ractors))
    end

    def self.finalizer(ractors)
      ->(_) {
        ractors.each { _1 << RactorPool::STOP; _1.join }
      }
    end

    def each(objects)
      map(objects)
      nil
    end

    def map(objects, &block)
      results = [] #: Array[untyped]

      thread = Thread.start do
        objects.each_slice(100) do |obj|
          ractor = worker_port.receive
          ractor.send(obj)
        end

        ractors.each { _1 << RactorPool::STOP }
      end

      # thread.join

      ractors.each do |ractor|
        results.concat(ractor.value)
      end

      results
    end

    def self.map(objects, size, &block)
      pool = RactorPool.new(size, &block)
      pool.map(objects)
    end
  end
end
