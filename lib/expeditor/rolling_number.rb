require 'expeditor/status'
require 'expeditor/ring_buffer'

module Expeditor
  # A RollingNumber holds some Status objects and it rolls statuses each `per`
  # time (default is 1 second). Once it reaches the end of statuses array, it
  # backs to start of statuses array and then reset the status and resumes
  # recording. This is done so that the statistics are recorded gradually with
  # short time interval rahter than reset all the record every wide time range
  # (default is 10 seconds).
  class RollingNumber
    def initialize(opts = {})
      @mutex = Mutex.new
      @ring = RingBuffer.new(opts.fetch(:size, 10)) do
        Expeditor::Status.new
      end
      @per_time = opts.fetch(:per, 1)
      @current_start = Time.now
    end

    # @params [Symbol] type
    def increment(type)
      @mutex.synchronize do
        update
        @ring.current.increment(type)
      end
    end

    # @return [Expeditor::Status] Newly created status
    def total
      @mutex.synchronize do
        update
        @ring.all.inject(Expeditor::Status.new) {|i, s| i.merge!(s) }
      end
    end

    # @deprecated Don't use, use `#total` instead.
    def current
      warn 'Expeditor::RollingNumber#current is deprecated. Please use #total instead to fetch correct status object.'
      @mutex.synchronize do
        update
        @ring.current
      end
    end

    private

    def update
      passing = last_passing
      if passing > 0
        @current_start = @current_start + @per_time * passing
        @ring.move(passing)
      end
    end

    def last_passing
      (Time.now - @current_start).div(@per_time)
    end
  end
end
