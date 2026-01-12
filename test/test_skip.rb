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
  SKIP_TESTS_FILES = ENV["RBS_SKIP_TESTS"]&.split(File::PATH_SEPARATOR)

  SKIP_TESTS =
    SKIP_TESTS_FILES&.each_with_object({}) do |file, hash|
      File.foreach(file) do |line|
        line.chomp!
        line.gsub!(/#.*/, "")
        line.strip!

        next if line.empty?

        name, message = line.split(/\s+/, 2)

        hash[name] = [file, message]
      end
    end

  if SKIP_TESTS
    def setup
      super

      file, message = SKIP_TESTS[name] || SKIP_TESTS[self.class.name]
      if file
        if message
          omit "Skip test by RBS_SKIP_TESTS(#{file}): #{message}"
        else
          omit "Skip test by RBS_SKIP_TESTS(#{file})"
        end
      end
    end

    def teardown
      case
      when passed?
        # nop
      else
        puts "💡You can skip this test `#{name}` by adding the name to `#{SKIP_TESTS_FILES.join('`, `')}`"
      end

      super
    end
  end
end
