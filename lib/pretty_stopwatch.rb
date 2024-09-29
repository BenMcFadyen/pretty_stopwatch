# frozen_string_literal: true

require_relative "pretty_stopwatch/version"

#
# Based on the Guava Stopwatch com.google.common.base.Stopwatch
# Credit: The Guava Authors
#
# = Basic Example:
#   stopwatch = Stopwatch::create_started
#   sleep(0.1)
#   stopwatch.stop # optional
#   puts "slept for #{stopwatch}" # to_s optional
#   Output: "slept for 0.1014ms"
#
# = Named Example:
#   stopwatch = Stopwatch::create_started(:foo)
#   sleep(0.1)
#   puts "slept for #{stopwatch.get(:foo)}"
#   Output: "slept for 0.1014ms"
#
# = Block Example:
#   stopwatch = Stopwatch::time{sleep 0.1}
#
# = Lambda Example:
#   lambda = -> {sleep 0.15}
#   stopwatch = Stopwatch::time(lambda)
#
# = Proc Example:
#   proc = Proc.new {sleep 0.15}
#   stopwatch = Stopwatch::time(proc)

#   stopwatch = Stopwatch::create_started(:foo)
#   sleep(0.1)
#   puts "slept for #{stopwatch.get(:foo)}"
#   Output: "slept for 0.1014ms"
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
    def create_started(name = nil, elapsed_nanos: 0)
      new(name, elapsed_nanos).start
    end

    def create_unstarted(name = nil, elapsed_nanos: 0)
      new(name, elapsed_nanos)
    end

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

  # reset the elapsed time and stop the stopwatch
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
