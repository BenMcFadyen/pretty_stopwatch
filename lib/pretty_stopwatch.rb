# frozen_string_literal: true

# A simple Stopwatch with nanosecond precision and readable formatting.
#
# Uses: Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond) to measure elapsed time.
#
# "The state-changing methods are not idempotent; it is an error to start or stop a stopwatch
# that is already in the desired state."
#
# Implementation based on the Guava Stopwatch class: 'com.google.common.base.Stopwatch' Credit: The Guava Authors
# @example Basic Usage
#     stopwatch = Stopwatch::create_started
#     sleep(0.1)
#     stopwatch.stop # optional
#     puts stopwatch # 100.02 ms
# @example Named:
#     stopwatch = Stopwatch::create_started(:foo)
#     sleep(5.01)
#     puts stopwatch # 'foo' elapsed: 5.01 s
# @example Block:
#     stopwatch = Stopwatch::time{sleep 61.02}
#     stopwatch.stopped? # true
#     puts stopwatch # 1.017 min
# @example Callable:
#     callable = -> {fast = true} # Proc.new {puts "bar"}
#     stopwatch = Stopwatch::time(callable)
#     puts stopwatch # 3.7 μs
# @example Reset:
#     stopwatch = Stopwatch::create_started
#     sleep(0.01) # 10ms
#     puts stopwatch.elapsed_nanos # 10378100
#     puts stopwatch.elapsed_millis # 10
#     puts stopwatch.reset.elapsed_millis # 0
class Stopwatch
  class IllegalStateError < StandardError
  end

  attr_reader :name
  attr_reader :running

  def initialize(name = nil, elapsed_nanos = 0) # optional variable
    @name = name
    @start_nanos = nil
    @running = false
    @elapsed_nanos = elapsed_nanos
  end

  # @return [Boolean]
  def running?
    @running
  end

  # @return [Boolean]
  def stopped?
    !@running
  end

  private_class_method :new # private constructor

  class << self
    # Creates a new Stopwatch, and starts it.
    #
    # @param name [String] (optional) the name of the Stopwatch
    # @param elapsed_nanos [Integer] (optional) elapsed_nanos (use for testing)
    # @return [Stopwatch]
    def create_started(name = nil, elapsed_nanos: 0)
      new(name, elapsed_nanos).start
    end

    # Creates a new Stopwatch, but does not start it.
    #
    # @param name [String] (optional) the name of the Stopwatch
    # @param elapsed_nanos [Integer] (optional) elapsed_nanos (use for testing)
    # @return [Stopwatch]
    def create_unstarted(name = nil, elapsed_nanos: 0)
      new(name, elapsed_nanos)
    end

    # Times the execution of the given callable/block using a new Stopwatch.
    #
    # @param callable [Callable] callable to execute and time
    # @param block [Block] block to execute and time
    # @return [Stopwatch] Stopped Stopwatch
    def time(callable = nil, &block)
      stopwatch = create_started
      if callable
        callable.call
      elsif block
        block.call # yield also valid
      else
        raise "no callable/block given" # todo
      end
      stopwatch.stop
    end
  end

  # Starts the Stopwatch
  # @return [Stopwatch]
  def start
    raise IllegalStateError, "Stopwatch is already running" if @running
    @running = true
    @start_nanos = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
    self
  end

  # Stops the Stopwatch
  # @return [Stopwatch]
  def stop
    raise IllegalStateError, "Stopwatch is already stopped" unless @running
    @elapsed_nanos += Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond) - @start_nanos
    @running = false
    self
  end

  # Stops the Stopwatch and resets the elapsed time
  # @return [Stopwatch]
  def reset
    @running = false
    @elapsed_nanos = 0
    self
  end

  # @return [Integer]
  def elapsed_nanos
    if running?
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
      return (now - @start_nanos) + @elapsed_nanos
    end
    @elapsed_nanos
  end

  # @return [Integer]
  def elapsed_millis
    elapsed_nanos / 1_000_000
  end

  # @return [String]
  def to_s
    value_with_unit = PrettyUnitFormatter.scale_nanos_with_unit(elapsed_nanos)
    return "'#{@name}' elapsed: #{value_with_unit}" if @name
    value_with_unit.to_s
  end

  class PrettyUnitFormatter
    @units = [
      {name: "day", divisor: 1_000_000_000 * 60 * 60 * 24},
      {name: "hour", divisor: 1_000_000_000 * 60 * 60},
      {name: "min", divisor: 1_000_000_000 * 60},
      {name: "s", divisor: 1_000_000_000},
      {name: "ms", divisor: 1_000_000},
      {name: "μs", divisor: 1_000},
      {name: "ns", divisor: 1}
    ]

    class << self
      def get_unit(nanos)
        found_unit = @units.find { |unit| nanos >= unit[:divisor] }
        raise "No matching unit found for #{nanos}" if found_unit.nil?
        found_unit
      end

      def scale_nanos_with_unit(nanos)
        return "0 ns" if nanos < 1
        unit = get_unit(nanos)
        value = nanos / unit[:divisor].to_f
        "#{format_float(value)} #{unit[:name]}"
      end

      # @return [String] Rounded to 3dp and with trailing zeros removed
      private def format_float(float)
        sprintf("%f", float.round(3)).sub(/\.?0*$/, "")
      end
    end
  end
end
