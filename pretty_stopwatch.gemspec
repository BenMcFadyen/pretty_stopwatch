# frozen_string_literal: true

require_relative "lib/pretty_stopwatch/version"

Gem::Specification.new do |spec|
  spec.name = "pretty_stopwatch"
  spec.version = PrettyStopwatch::VERSION
  spec.authors = ["Ben Mcfadyen"]
  spec.email = ["ben.mcfadyen3@gmail.com"]

  spec.summary = "A simple Stopwatch with nanosecond precision and readable formatting."
  spec.description = "A simple Stopwatch with nanosecond precision and readable formatting."
  spec.homepage = "https://github.com/BenMcFadyen/pretty_stopwatch"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/BenMcFadyen/pretty_stopwatch"
  spec.metadata["changelog_uri"] = "https://github.com/BenMcFadyen/pretty_stopwatch"
  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec", "~> 3.2"
end
