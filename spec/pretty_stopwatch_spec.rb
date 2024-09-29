# frozen_string_literal: true
require "pretty_stopwatch"

RSpec.describe PrettyStopwatch do

  it "has a version number" do
    expect(PrettyStopwatch::VERSION).not_to be nil
  end

  # lifecycle tests
  it "should return a running stopwatch when created using create_started" do
    stopwatch = Stopwatch::create_started
    expect(stopwatch.running?).to be true
  end


  it "should return a stopped stopwatch when created using create_unstarted" do
    stopwatch = Stopwatch::create_unstarted
    expect(stopwatch.stopped?).to be true
  end

  it "should execute the block and return a stopped stopwatch" do
    stopwatch = Stopwatch::time{sleep 0.01}
    expect(stopwatch.stopped?).to eq(true)
  end

  it "should execute the proc and return a stopped stopwatch" do
    proc = Proc.new{puts "nice proc!"}
    stopwatch = Stopwatch::time(proc)
    expect(stopwatch.stopped?).to eq(true)
  end

  it "should execute the lambda and return a stopped stopwatch" do
    lambda = -> {puts "hello"}
    stopwatch = Stopwatch::time(lambda)
    expect(stopwatch.stopped?).to eq(true)
  end

  it "should pause the stopwatch when stopped" do
    stopwatch = Stopwatch::create_started
    expect(stopwatch.running?).to be true
    stopwatch.stop
    expect(stopwatch.stopped?).to be true
  end

  it "should start the stopwatch when started" do
    stopwatch = Stopwatch::create_unstarted
    expect(stopwatch.stopped?).to be true
    stopwatch.start
    expect(stopwatch.running?).to be true
  end

  it "should raise IllegalStateError when started twice" do
    stopwatch = Stopwatch::create_started
    expect{stopwatch.start}.to raise_error(Stopwatch::IllegalStateError, "Stopwatch is already running")
  end

  it "should raise IllegalStateError when stopped twice" do
    stopwatch = Stopwatch::create_unstarted
    expect{stopwatch.stop}.to raise_error(Stopwatch::IllegalStateError, "Stopwatch is already stopped")
  end

  it "should reset the elapsed time when reset" do
    stopwatch = Stopwatch::create_started
    sleep(0.2)
    millis = stopwatch.elapsed_millis
    expect(millis).to eq(200)
    stopwatch.reset
    expect(stopwatch.elapsed_millis).to be 0
  end

  it "should reset stop the stopwatch when reset" do
    stopwatch = Stopwatch::create_started(elapsed_nanos: 100)
    stopwatch.reset
    expect(stopwatch.stopped?).to be true
    expect(stopwatch.elapsed_nanos).to be 0
  end

  it "should return 0 if not started" do
    stopwatch = Stopwatch::create_unstarted
    expect(stopwatch.elapsed_nanos).to be 0
    expect(stopwatch.elapsed_millis).to be 0
  end

  it "should return 1 millis" do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 1_000_000)
    expect(stopwatch.elapsed_millis).to be 1
  end

  it "should return 1_000_000 nanos" do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 1_000_000)
    expect(stopwatch.elapsed_nanos).to be 1_000_000
  end

  it "should not increase elapsed_millis once stopped" do
    stopwatch = Stopwatch::create_started
    sleep(0.1)
    stopwatch.stop
    expect(stopwatch.elapsed_millis).to be_within(1).of(100)
    sleep(0.1)
    expect(stopwatch.elapsed_millis).to be_within(1).of(100)
  end

  it "should return elapsed millis, counting only time when the stopwatch was running" do
    stopwatch = Stopwatch::create_started
    sleep(0.1)
    stopwatch.stop
    expect(stopwatch.elapsed_millis).to be_within(1).of(100)
    sleep(0.2) # stopwatch shouldn't be running for this sleep
    expect(stopwatch.elapsed_millis).to be_within(1).of(100)
    stopwatch.start
    sleep(0.3)
    expect(stopwatch.elapsed_millis).to be_within(1).of(400)
  end

  it "should return elapsed millis once stopped, counting only time when the stopwatch was running" do
    stopwatch = Stopwatch::create_started
    sleep(0.1)
    stopwatch.stop
    expect(stopwatch.elapsed_millis).to be_within(1).of(100)
    sleep(0.2) # stopwatch shouldn't be running for this sleep
    expect(stopwatch.elapsed_millis).to be_within(1).of(100)
    stopwatch.start
    sleep(0.3)
    stopwatch.stop
    expect(stopwatch.elapsed_millis).to be_within(1).of(400)
  end

  it "should not increase elapsed_nanos once stopped" do
    stopwatch = Stopwatch::create_started
    sleep(0.1) # 100ms
    stopwatch.stop
    expect(stopwatch.elapsed_nanos).to be_within(1_000_000).of(1_000_000 * 100)
    sleep(0.1) # 100ms
    expect(stopwatch.elapsed_nanos).to be_within(1_000_000).of(1_000_000 * 100)
  end


  context 'when stopwatch is started, stopped and started again' do
    it 'should return elapsed_nanos counting only time when the stopwatch was running' do
      stopwatch = Stopwatch::create_started
      sleep(0.1) # 100ms
      stopwatch.stop
      expect(stopwatch.elapsed_nanos).to be_within(1_000_000).of(1_000_000 * 100)
      sleep(0.3) # stopwatch shouldn't be running for this sleep
      expect(stopwatch.elapsed_nanos).to be_within(1_000_000).of(1_000_000 * 100)
      stopwatch.start
      sleep(0.2) # 2ms
      expect(stopwatch.elapsed_nanos).to be_within(1_000_000).of(3_000_000 * 100)
    end
  end

  context 'when stopwatch is started and stopped multiple times' do
    it 'should return elapsed_nanos counting only time when the stopwatch was running' do
      stopwatch = Stopwatch::create_started
      sleep(0.1) # 100ms
      stopwatch.stop
      expect(stopwatch.elapsed_nanos).to be_within(1_000_000).of(1_000_000 * 100)
      sleep(0.3) # stopwatch shouldn't be running for this sleep
      expect(stopwatch.elapsed_nanos).to be_within(1_000_000).of(1_000_000 * 100)
      stopwatch.start
      sleep(0.2) # 2ms
      stopwatch.stop
      expect(stopwatch.elapsed_nanos).to be_within(3_000_000).of(3_000_000 * 100)
    end
  end


  it 'should return ns' do
    [1, 999].each do |value|
      unit = Stopwatch::PrettyUnitFormatter.get_unit(value)
      expect(unit[:name]).to eq("ns")
    end
  end

  it 'should return μs' do
    [1000, 1001, 999_999].each do |value|
      unit = Stopwatch::PrettyUnitFormatter.get_unit(value)
      expect(unit[:name]).to eq("μs")
    end
  end

  it 'should return ms' do
    [1_000_000, 1_000_001, 1_001_000, 999_999_999].each do |value|
      unit = Stopwatch::PrettyUnitFormatter.get_unit(value)
      expect(unit[:name]).to eq("ms")
    end
  end

  it 'should return s' do
    [1_000_000_001, 1_110_000_001, 1_001_000_000, 59_999_999_999].each do |value|
      unit = Stopwatch::PrettyUnitFormatter.get_unit(value)
      expect(unit[:name]).to eq("s")
    end
  end

  it 'should return min' do
    [60_000_000_000, 60_000_000_001, 67_110_000_000].each do |value|
      unit = Stopwatch::PrettyUnitFormatter.get_unit(value)
      expect(unit[:name]).to eq("min")
    end
  end

  it 'should return hour' do
    [3_600_000_000_000, 3_600_000_000_001, 86_399_999_999_999].each do |value|
      unit = Stopwatch::PrettyUnitFormatter.get_unit(value)
      expect(unit[:name]).to eq("hour")
    end
  end

  it 'should return day' do
    [86_400_000_000_000, 86_400_000_000_001].each do |value|
      unit = Stopwatch::PrettyUnitFormatter.get_unit(value)
      expect(unit[:name]).to eq("day")
    end
  end

  it 'should return 0 ns' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 0)
    expect("#{stopwatch}").to eq("0 ns")
  end

  it 'should return 1 ns' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 1)
    expect("#{stopwatch}").to eq("1 ns")
  end

  it 'should return 999 ns' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 999)
    expect("#{stopwatch}").to eq("999 ns")
  end

  it 'should return 1 μs' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 1000)
    expect("#{stopwatch}").to eq("1 μs")
  end

  it 'should return 1.001 μs' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 1001)
    expect("#{stopwatch}").to eq("1.001 μs")
  end

  it 'should return 1 ms' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 1_000_000)
    expect("#{stopwatch}").to eq("1 ms")
  end

  it 'should return 1.001 ms' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 1_001_000)
    expect("#{stopwatch}").to eq("1.001 ms")
  end

  it 'should return 999.1 ms' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 999_100_000)
    expect("#{stopwatch}").to eq("999.1 ms")
  end

  it 'should return 1000 ms' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 999_999_900)
    expect("#{stopwatch}").to eq("1000 ms")
  end

  it 'should return 1 s' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 1_000_000_001)
    expect("#{stopwatch}").to eq("1 s")
  end

  it 'should return 1.11 s' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 1_110_000_001)
    expect("#{stopwatch}").to eq("1.11 s")
  end

  it 'should return 1.001 s' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 1_001_000_000)
    expect("#{stopwatch}").to eq("1.001 s")
  end

  it 'should return 59.999 s' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 59_999_000_000)
    expect("#{stopwatch}").to eq("59.999 s")
  end

  it 'should return 1 min' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 60_000_000_000)
    expect("#{stopwatch}").to eq("1 min")
  end

  it 'should return 1.001 min' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 60_060_000_000)
    expect("#{stopwatch}").to eq("1.001 min")
  end

  it 'should return 59.999 min' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 3_599_940_000_000)
    expect("#{stopwatch}").to eq("59.999 min")
  end

  it 'should return 1 hour' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 3_600_000_000_000)
    expect("#{stopwatch}").to eq("1 hour")
  end

  it 'should return 23.999 hour' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 86_396_400_000_000)
    expect("#{stopwatch}").to eq("23.999 hour")
  end

  it 'should return 1 day' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 86_400_000_000_000)
    expect("#{stopwatch}").to eq("1 day")
  end

  it 'should return 1 day' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: 86_400_000_000_000)
    expect("#{stopwatch}").to eq("1 day")
  end

  it 'should return 365 day' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos:  1_000_000_000 * 60 * 60 * 24 * 365)
    expect("#{stopwatch}").to eq("365 day")
  end

  it 'should return' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: Float::MAX)
    expect("#{stopwatch}").not_to be_nil
  end

  it 'should return' do
    stopwatch = Stopwatch::create_unstarted(elapsed_nanos: Float::INFINITY)
    expect("#{stopwatch}").not_to be_nil
  end


  it 'should just print elapsed time if name is nil' do
    stopwatch = Stopwatch::create_unstarted(nil, elapsed_nanos: 1_000_000)
    expect("#{stopwatch}").to eq("1 ms")
  end

  it 'should print the stopwatch name along with the elapsed time' do
    stopwatch = Stopwatch::create_unstarted("foo", elapsed_nanos: 1_000_000)
    expect("#{stopwatch}").to eq("'foo' elapsed: 1 ms")
  end

end
