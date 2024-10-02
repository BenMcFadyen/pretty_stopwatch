# PrettyStopwatch

A simple Stopwatch with nanosecond precision and readable formatting.

### Basic Usage
    stopwatch = Stopwatch::create_started
    sleep(0.1)
    stopwatch.stop # optional
    puts stopwatch # 100.02 ms
### Named:
    stopwatch = Stopwatch::create_started(:foo)
    sleep(5.01)
    puts stopwatch # 'foo' elapsed: 5.01 s
### Block:
    stopwatch = Stopwatch::time{sleep 61.02}
    stopwatch.stopped? # true
    puts stopwatch # 1.017 min
### Callable:
    callable = -> {fast = true} # Proc.new {puts "bar"}
    stopwatch = Stopwatch::time(callable)
    puts stopwatch # 3.7 μs
### Reset:
    stopwatch = Stopwatch::create_started
    sleep(0.01) # 10ms
    puts stopwatch.elapsed_nanos # 10378100
    puts stopwatch.elapsed_millis # 10
    puts stopwatch.reset.elapsed_millis # 0

Based on the Guava Stopwatch com.google.common.base.Stopwatch. Credit: The Guava Authors

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add pretty_stopwatch

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install pretty_stopwatch

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
