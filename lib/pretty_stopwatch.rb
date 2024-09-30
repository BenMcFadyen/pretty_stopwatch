# frozen_string_literal: true

# A simple Stopwatch with nanosecond precision and readable formatting.
# ``` Basic Usage
#     stopwatch = Stopwatch::create_started
#     sleep(0.1)
#     stopwatch.stop # optional
#     puts "slept for #{stopwatch}" # to_s optional
#     # slept for 100.02 ms
# ```
#  Named:
#     stopwatch = Stopwatch::create_started(:foo)
#     sleep(0.2)
#     puts "#{stopwatch}"
#     'foo' elapsed: 200.235 ms
#  Block:
#     stopwatch = Stopwatch::time{sleep 0.1}
#  Lambda:
#     lambda = -> {sleep 0.15}
#     stopwatch = Stopwatch::time(lambda)
#  Proc:
#     proc = Proc.new {sleep 0.15}
#     stopwatch = Stopwatch::time(proc)
#
# Uses: Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond) to measure elapsed time.
#
# The state-changing methods are not idempotent; it is an error to start or stop a stopwatch
# that is already in the desired state.
#
# Implementation based on the Guava Stopwatch class: 'com.google.common.base.Stopwatch' Credit: The Guava Authors
class Stopwatch

  # Stopwatch methods are not idempotent; it is an error to start or stop a stopwatch that is already in the desired state.
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

  def running?
    @running
  end

  def stopped?
    !@running
  end

  private_class_method :new # private constructor

  class << self


    # Creates a new Stopwatch, and starts it.
    #
    # @param [String] name - (optional) - name of the stopwatch.
    # * +elapsed_nanos+ - (optional) - elapsed_nanos value for the Stopwatch.
    def create_started(name = nil, elapsed_nanos: 0)
      new(name, elapsed_nanos).start
    end

    # Creates a new Stopwatch, but does not start it.
    #
    # * +name+ - (optional) - name of the stopwatch.
    # * +elapsed_nanos+ - (optional) - elapsed_nanos value for the Stopwatch.
    def create_unstarted(name = nil, elapsed_nanos: 0)
      new(name, elapsed_nanos)
    end

    # Creates a new Stopwatch, executes the given callable/block, returns the stopped Stopwatch.
    #
    # * +callable+ - callable to execute
    # * +block+ - (optional) - elapsed_nanos value for the Stopwatch.
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

  def start
    raise IllegalStateError, "Stopwatch is already running" if @running
    @running = true
    @start_nanos = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
    self
  end

  def stop
    raise IllegalStateError, "Stopwatch is already stopped" unless @running
    @elapsed_nanos += Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond) - @start_nanos
    @running = false
    self
  end

  # reset the elapsed time and stops the Stopwatch.
  def reset
    @running = false
    @elapsed_nanos = 0
  end

  def elapsed_nanos
    if running?
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)
      return (now - @start_nanos) + @elapsed_nanos
    end
    @elapsed_nanos
  end

  def elapsed_millis
    elapsed_nanos / 1_000_000
  end

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
        return "0 ns" if nanos.zero?
        unit = get_unit(nanos)
        value = nanos / unit[:divisor].to_f
        "#{format_float(value)} #{unit[:name]}"
      end

      # format float to 3dp & remove trailing zeros
      private def format_float(float)
        sprintf("%f", float.round(3)).sub(/\.?0*$/, "")
      end
    end
  end
end
