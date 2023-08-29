# Including this module allows `omit` test cases based on an external file, not in the source code
#
# The file contains a list of the names of the test cases to skip:
#
# ```
# test_foo(RBS::UnitTest)            # Test case name
# RBS::CLICtest                      # Test class name
# test_collection_install(CLITest) requires bundler setup   # Can have comments
# ```
#
# And start tests with `$RBS_SKIP_TESTS` env var:
#
# ```
# $ RBS_SKIP_TESTS=../rbs_skip_tests rake test
# ```
#
module TestSkip
  env = ENV["RBS_SKIP_TESTS"]
  SKIP_TESTS_FILE =
    if env
      Pathname(env)
    end

  SKIP_TESTS =
    if SKIP_TESTS_FILE
      SKIP_TESTS_FILE.each_line.with_object({}) do |line, hash|
        line.chomp!
        line.gsub!(/#.*/, "")
        line.strip!

        next if line.empty?

        name, message = line.split(/\s+/, 2)

        hash[name] = message
      end
    end

  if SKIP_TESTS
    def setup
      super

      if SKIP_TESTS.key?(name) || SKIP_TESTS.key?(self.class.name)
        if message = SKIP_TESTS[name] || SKIP_TESTS[self.class.name]
          omit "Skip test by RBS_SKIP_TESTS(#{SKIP_TESTS_FILE}): #{message}"
        else
          omit "Skip test by RBS_SKIP_TESTS(#{SKIP_TESTS_FILE})"
        end
      end
    end

    def teardown
      case
      when passed?
        # nop
      else
        puts "💡You can skip this test `#{name}` by adding the name to `#{SKIP_TESTS_FILE}`"
      end

      super
    end
  end
end
