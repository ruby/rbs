require "bundler/gem_tasks"
require "rake/testtask"
require "rbconfig"
require 'rake/extensiontask'

$LOAD_PATH << File.join(__dir__, "test")

ruby = ENV["RUBY"] || RbConfig.ruby
rbs = File.join(__dir__, "exe/rbs")
bin = File.join(__dir__, "bin")

Rake::ExtensionTask.new("rbs_extension")

compile_task = Rake::Task[:compile]

task :setup_extconf_compile_commands_json do
  ENV["COMPILE_COMMANDS_JSON"] = "1"
end

compile_task.prerequisites.unshift(:setup_extconf_compile_commands_json)

test_config = lambda do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"].reject do |path|
    path =~ %r{test/stdlib/}
  end
  if defined?(RubyMemcheck)
    if t.is_a?(RubyMemcheck::TestTask)
      t.verbose = true
      t.options = '-v'
    end
  end
end

if RUBY_ENGINE == "jruby"
  # JRuby runs the parser in WebAssembly instead of the C extension, so there is
  # nothing to compile. The wasm runtime must be assembled first with
  # `rake wasm:jruby_setup` (which needs CRuby + the WASI SDK).
  Rake::TestTask.new(:test, &test_config)
else
  Rake::TestTask.new(test: :compile, &test_config)
end

multitask :default => [:test, :stdlib_test, :typecheck_test, :rubocop, :validate, :test_doc]

task :lexer do
  sh "re2c -W --no-generation-date -o src/lexer.c src/lexer.re"
  sh "clang-format -i -style=file src/lexer.c"
end

task :confirm_lexer => :lexer do
  puts "Testing if lexer.c is updated with respect to lexer.re"
  sh "git diff --exit-code src/lexer.c"
end

task :confirm_templates => :templates do
  puts "Testing if generated code is updated with respect to templates"

  # Every template generates the file it is named after: `templates/<path>.erb` generates `<path>`.
  generated = Dir.glob("templates/**/*.erb").sort.map { _1.delete_prefix("templates/").delete_suffix(".erb") }

  missing = generated.reject { File.exist?(_1) }
  raise "Templates without a generated file: #{missing.join(", ")}. Is the `templates` task missing an entry?" unless missing.empty?

  sh "git diff --exit-code -- #{generated.join(" ")}"
end

# Task to format C code using clang-format
namespace :format do
  dirs = ["src", "ext", "include"]

  # Find all C source and header files
  files = `find #{dirs.join(" ")} -type f \\( -name "*.c" -o -name "*.h" \\)`.split("\n")

  desc "Format C source files using clang-format"
  task :c do
    puts "Formatting C files..."

    # Check if clang-format is installed
    unless system("which clang-format > /dev/null 2>&1")
      abort "Error: clang-format not found. Please install clang-format first."
    end

    if files.empty?
      puts "No C files found to format"
      next
    end

    puts "Found #{files.length} files to format (excluding generated files)"

    exit_status = 0
    files.each do |file|
      puts "Formatting #{file}"
      unless system("clang-format -i -style=file #{file}")
        puts "❌ Error formatting #{file}"
        exit_status = 1
      end
    end

    exit exit_status unless exit_status == 0
    puts "✅ All files formatted successfully"
  end

  desc "Check if C source files are properly formatted"
  task :c_check do
    puts "Checking C file formatting..."

    # Check if clang-format is installed
    unless system("which clang-format > /dev/null 2>&1")
      abort "Error: clang-format not found. Please install clang-format first."
    end

    if files.empty?
      puts "No C files found to check"
      next
    end

    puts "Found #{files.length} files to check (excluding generated files)"

    needs_format = false
    files.each do |file|
      formatted = `clang-format -style=file #{file}`
      original = File.read(file)

      if formatted != original
        puts "❌ #{file} needs formatting"
        puts "Diff:"
        # Save formatted version to temp file and run diff
        temp_file = "#{file}.formatted"
        File.write(temp_file, formatted)
        system("diff -u #{file} #{temp_file}")
        File.unlink(temp_file)
        needs_format = true
      end
    end

    if needs_format
      warn "Some files need formatting. Run 'rake format:c' to format them."
      exit 1
    else
      puts "✅ All files are properly formatted"
    end
  end
end

rule ".c" => ".re" do |t|
  puts "⚠️⚠️⚠️ #{t.name} is older than #{t.source}. You may need to run `rake lexer` ⚠️⚠️⚠️"
end

rule %r{^src/(.*)\.c} => 'templates/%X.c.erb' do |t|
  puts "⚠️⚠️⚠️ #{t.name} is older than #{t.source}. You may need to run `rake templates` ⚠️⚠️⚠️"
end
rule %r{^include/(.*)\.c} => 'templates/%X.c.erb' do |t|
  puts "⚠️⚠️⚠️ #{t.name} is older than #{t.source}. You may need to run `rake templates` ⚠️⚠️⚠️"
end
rule %r{^ext/(.*)\.c} => 'templates/%X.c.erb' do |t|
  puts "⚠️⚠️⚠️ #{t.name} is older than #{t.source}. You may need to run `rake templates` ⚠️⚠️⚠️"
end

task :annotate do
  sh "bin/generate_docs.sh"
end

task :confirm_annotation do
  puts "Testing if RBS docs are updated with respect to RDoc"
  sh "git diff --exit-code core stdlib"
end

task :templates do
  sh "#{ruby} templates/template.rb ext/rbs_extension/ast_translation.h"
  sh "#{ruby} templates/template.rb ext/rbs_extension/ast_translation.c"

  sh "#{ruby} templates/template.rb ext/rbs_extension/class_constants.h"
  sh "#{ruby} templates/template.rb ext/rbs_extension/class_constants.c"

  sh "#{ruby} templates/template.rb include/rbs/ast.h"
  sh "#{ruby} templates/template.rb src/ast.c"

  sh "#{ruby} templates/template.rb include/rbs/serialize.h"
  sh "#{ruby} templates/template.rb src/serialize.c"
  sh "#{ruby} templates/template.rb lib/rbs/wasm/serialization_schema.rb"

  # Format the generated files
  Rake::Task["format:c"].invoke
end

task :compile => "ext/rbs_extension/class_constants.h"
task :compile => "ext/rbs_extension/class_constants.c"
task :compile => "src/lexer.c"

task :test_doc do
  files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").select do |file| Pathname(file).extname == ".md" end
  end

  sh "#{ruby} #{__dir__}/bin/run_in_md.rb #{files.join(" ")}"
end

task :validate => :compile do
  require 'yaml'

  sh "#{ruby} #{rbs} validate"

  libs = FileList["stdlib/*"].map {|path| File.basename(path).to_s }

  # Skip RBS validation because Ruby CI runs without rubygems
  case skip_rbs_validation = ENV["SKIP_RBS_VALIDATION"]
  when nil
    begin
      Gem::Specification.find_by_name("rbs")
      libs << "rbs"
    rescue Gem::MissingSpecError
      STDERR.puts "🚨🚨🚨🚨 Skipping `rbs` gem because it's not found"
    end
  when "true"
    # Skip
  else
    STDERR.puts "🚨🚨🚨🚨 SKIP_RBS_VALIDATION is expected to be `true` or unset, given `#{skip_rbs_validation}` 🚨🚨🚨🚨"
    libs << "rbs"
  end

  libs.delete("bigdecimal-math") or raise
  libs.delete("bigdecimal") or raise

  libs.each do |lib|
    args = ["-r", lib]

    if lib == "rbs"
      args << "-r" << "prism"
      args << "-r" << "logger"
    end

    sh "#{ruby} #{rbs} #{args.join(' ')} validate"
  end
end

FileList["test/stdlib/**/*_test.rb"].each do |test|
  task test => :compile do
    sh "#{ruby} -Ilib #{bin}/test_runner.rb #{test}"
  end
end

task :stdlib_test => :compile do
  test_files = FileList["test/stdlib/**/*_test.rb"].reject do |path|
    path =~ %r{Ractor} || path =~ %r{Encoding} || path =~ %r{CGI-escape_test}
  end

  if ENV["RANDOMIZE_STDLIB_TEST_ORDER"] == "true"
    test_files.shuffle!
  end

  sh "#{ruby} -Ilib #{bin}/test_runner.rb #{test_files.join(' ')}"
  # TODO: Ractor tests need to be run in a separate process
  sh "#{ruby} -Ilib #{bin}/test_runner.rb test/stdlib/CGI-escape_test.rb"
  sh "#{ruby} -Ilib #{bin}/test_runner.rb test/stdlib/Ractor_test.rb"
  sh "#{ruby} -Ilib #{bin}/test_runner.rb test/stdlib/Encoding_test.rb"
end

task :typecheck_test => :compile do
  FileList["test/typecheck/*"].each do |test|
    Dir.chdir(test) do
      expectations = File.join(test, "steep_expectations.yml")
      if File.exist?(expectations)
        sh "steep check --with_expectations"
      else
        sh "steep check"
      end
    end
  end
end

task :raap => :compile do
  sh "ruby test/raap/core.rb"
  sh "ruby test/raap/digest.rb"
  sh "ruby test/raap/openssl.rb"
end

task :rubocop do
  format = if ENV["CI"]
    "github"
  else
    "progress"
  end

  sh "rubocop --parallel --format #{format}"
end

namespace :generate do
  desc "Generate a test file for a stdlib class signatures"
  task :stdlib_test, [:class] do |_task, args|
    klass = args.fetch(:class) do
      raise "Class name is necessary. e.g. rake 'generate:stdlib_test[String]'"
    end

    require "erb"
    require "rbs"

    class TestTarget
      def initialize(klass)
        @type_name = RBS::Namespace.parse(klass).to_type_name
      end

      def path
        Pathname(ENV['RBS_GENERATE_TEST_PATH'] || "test/stdlib/#{file_name}_test.rb")
      end

      def file_name
        @type_name.to_s.gsub(/\A::/, '').gsub(/::/, '_')
      end

      def to_s
        @type_name.to_s
      end

      def absolute_type_name
        @absolute_type_name ||= @type_name.absolute!
      end
    end

    target = TestTarget.new(klass)
    path = target.path
    raise "#{path} already exists!" if path.exist?

    class TestTemplateBuilder
      attr_reader :target, :env

      def initialize(target, paths:)
        @target = target

        loader = RBS::EnvironmentLoader.new
        paths.each { loader.add(path: Pathname(_1)) }
        @env = RBS::Environment.from_loader(loader).resolve_type_names
      end

      def call
        ERB.new(<<~ERB, trim_mode: "-").result(binding)
          require_relative "test_helper"

          <%- unless class_methods.empty? -%>
          class <%= target %>SingletonTest < Test::Unit::TestCase
            include TestHelper

            # library "logger", "securerandom"     # Declare library signatures to load
            testing "singleton(::<%= target %>)"

          <%- class_methods.each do |method_name, definition| -%>
            def test_<%= test_name_for(method_name) %>
          <%- definition.method_types.each do |method_type| -%>
              assert_send_type "<%= method_type %>",
                               <%= target %>, :<%= method_name %>
          <%- end -%>
            end

          <%- end -%>
          end
          <%- end -%>

          <%- unless instance_methods.empty? -%>
          class <%= target %>Test < Test::Unit::TestCase
            include TestHelper

            # library "logger", "securerandom"     # Declare library signatures to load
            testing "::<%= target %>"

          <%- instance_methods.each do |method_name, definition| -%>
            def test_<%= test_name_for(method_name) %>
          <%- definition.method_types.each do |method_type| -%>
              assert_send_type "<%= method_type %>",
                               <%= target %>.new, :<%= method_name %>
          <%- end -%>
            end

          <%- end -%>
          end
          <%- end -%>
        ERB
      end

      private

      def test_name_for(method_name)
        {
          :==  => 'double_equal',
          :!=  => 'not_equal',
          :=== => 'triple_equal',
          :[]  => 'square_bracket',
          :[]= => 'square_bracket_assign',
          :>   => 'greater_than',
          :<   => 'less_than',
          :>=  => 'greater_than_equal_to',
          :<=  => 'less_than_equal_to',
          :<=> => 'spaceship',
          :+   => 'plus',
          :-   => 'minus',
          :*   => 'multiply',
          :/   => 'divide',
          :**  => 'power',
          :%   => 'modulus',
          :&   => 'and',
          :|   => 'or',
          :^   => 'xor',
          :>>  => 'right_shift',
          :<<  => 'left_shift',
          :=~  => 'pattern_match',
          :!~  => 'does_not_match',
          :~   => 'tilde'
        }.fetch(method_name, method_name)
      end

      def class_methods
        @class_methods ||= RBS::DefinitionBuilder.new(env: env).build_singleton(target.absolute_type_name).methods.select {|_, definition|
          definition.implemented_in == target.absolute_type_name
        }
      end

      def instance_methods
        @instance_methods ||= RBS::DefinitionBuilder.new(env: env).build_instance(target.absolute_type_name).methods.select {|_, definition|
          definition.implemented_in == target.absolute_type_name
        }
      end
    end

    path.write TestTemplateBuilder.new(target, paths: args.extras).call

    puts "Created: #{path}"
  end
end

task :test_generate_stdlib do
  sh "RBS_GENERATE_TEST_PATH=/tmp/Array_test.rb rake 'generate:stdlib_test[Array]'"
  sh "ruby -c /tmp/Array_test.rb"
  sh "RBS_GENERATE_TEST_PATH=/tmp/Thread_Mutex_test.rb rake 'generate:stdlib_test[Thread::Mutex]'"
  sh "ruby -c /tmp/Thread_Mutex_test.rb"
  sh "RBS_GENERATE_TEST_PATH=/tmp/Kconv_test.rb rake 'generate:stdlib_test[Kconv,stdlib/nkf/0,stdlib/kconv/0]'"
  sh "ruby -c /tmp/Kconv_test.rb"
end

# Pull requests with one of these labels are omitted from the changelog.
CHANGELOG_SKIP_LABELS = ["skip-changelog"]

# Resolves the commit-ish the changelog starts from.
#
# `version` is a version number, a tag, or any commit-ish. When it is omitted, the latest tag
# matching `tag_glob` is used, skipping the ones matching `exclude_globs`.
#
def resolve_changelog_base(version, tag_glob:, exclude_globs: [])
  require "open3"

  from =
    if version
      # `4.1.0` and `v4.1.0` both mean the tag `v4.1.0`, while `master` or a SHA is used as is.
      version.match?(/\A\d/) ? "v#{version}" : version
    else
      command = ["git", "describe", "--tags", "--match", tag_glob, "--abbrev=0"]
      exclude_globs.each { |glob| command.push("--exclude", glob) }

      output, status = Open3.capture2(*command)
      raise "🚨 Cannot detect the latest tag matching `#{tag_glob}`. Give the previous version explicitly." unless status.success?
      output.chomp
    end

  _, status = Open3.capture2("git", "rev-parse", "--verify", "--quiet", "#{from}^{commit}")
  raise "🚨 No such commit-ish: `#{from}`" unless status.success?

  from
end

# Runs a GraphQL query against the repository of the working directory.
#
# `body` is the selection set inside `repository`, so a query can use the `$owner` and `$name`
# variables. Returns the contents of `data.repository`.
#
def changelog_graphql(body)
  require "open3"
  require "json"

  @changelog_repository ||=
    begin
      output, status = Open3.capture2("gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner")
      raise status.inspect unless status.success?
      output.chomp.split("/", 2)
    end
  owner, name = @changelog_repository

  query = <<~GRAPHQL
    query($owner: String!, $name: String!) {
      repository(owner: $owner, name: $name) {
        #{body}
      }
    }
  GRAPHQL

  output, status = Open3.capture2(
    "gh", "api", "graphql",
    "-f", "query=#{query}",
    "-f", "owner=#{owner}",
    "-f", "name=#{name}",
    binmode: true
  )
  raise status.inspect unless status.success?

  # GitHub always answers in UTF-8, while the default external encoding follows the locale. Without
  # this, a pull request body with an emoji fails to parse under `LANG=C`, as in GitHub Actions.
  JSON.parse(output.force_encoding(Encoding::UTF_8), symbolize_names: true).dig(:data, :repository)
end

# Lists the commits between `from` and `HEAD`, newest first.
#
# Giving `paths` limits the commits to the ones touching the paths.
#
def changelog_commits(from, paths: [])
  require "open3"

  command = ["git", "log", "--format=%H", "#{from}..HEAD"]
  # `--simplify-merges` keeps the default history simplification from following only one parent of
  # a merge commit, which can drop the other side. Note that `--full-history` alone is wrong here:
  # it also lists merge commits that do not touch the paths, bringing back the excluded pull
  # requests. The two flags produce the same commits as the default mode for this repository today.
  command.push("--full-history", "--simplify-merges", "--", *paths) unless paths.empty?

  output, status = Open3.capture2(*command)
  raise status.inspect unless status.success?

  output.lines.map(&:chomp).reject(&:empty?)
end

# What `git cherry-pick -x` appends to the message of the commit it creates.
CHERRY_PICK_ORIGIN = /^\(cherry picked from commit ([0-9a-f]{40})\)$/

# Maps the commits that record where they were cherry-picked from to that commit.
#
# A backport is a cherry-pick, so on a release branch it is the recorded origin, not the commit
# itself, that leads to the pull request the change was written and reviewed in. Without this a
# backported change is attributed to the pull request that carried the backport, which says
# nothing about the change and is the same for every commit it brought over.
#
# A commit backported twice -- the development line, then a release branch -- carries one line
# per hop, appended in order, so the first one is where the change started.
#
def changelog_origins(commits)
  return {} if commits.empty?

  require "open3"

  # `--no-walk` prints these commits and nothing else. NUL delimiters keep a commit message --
  # which can contain anything, including what this format looks like -- from being read as the
  # format itself.
  output, status = Open3.capture2("git", "log", "--no-walk", "--format=%H%x00%B%x00", *commits, binmode: true)
  raise status.inspect unless status.success?

  # Commit messages are UTF-8, while the default external encoding follows the locale. Without
  # this, splitting a message that is not ASCII fails under `LANG=C`, as in GitHub Actions.
  output.force_encoding(Encoding::UTF_8)

  output.split("\0").each_slice(2).each_with_object({}) do |(commit, message), origins|
    commit = commit.to_s.strip
    next if commit.empty?

    origin = message.to_s[CHERRY_PICK_ORIGIN, 1] or next
    origins[commit] = origin
  end
end

# Asks GitHub which pull requests each commit came from, so that any merge strategy -- merge
# commit, squash, or rebase -- is handled without parsing commit messages.
#
# Returns `{ oid => [pull request, ...] }`, with an empty array for the commits GitHub has no
# merged pull request for, including the ones it does not know at all.
#
def changelog_associated_pull_requests(oids)
  oids.uniq.each_slice(50).each_with_object({}) do |slice, found|
    aliases = slice.map.with_index do |oid, index|
      <<~GRAPHQL
        c#{index}: object(oid: "#{oid}") {
          ... on Commit {
            associatedPullRequests(first: 10) {
              nodes {
                number title url merged
                labels(first: 100) { nodes { name } }
              }
            }
          }
        }
      GRAPHQL
    end

    response = changelog_graphql(aliases.join("\n"))

    slice.each_with_index do |oid, index|
      nodes = response.dig(:"c#{index}", :associatedPullRequests, :nodes) || []

      found[oid] = nodes.select { |pr| pr[:merged] }.map do |pr|
        { number: pr[:number], title: pr[:title], url: pr[:url], labels: pr.dig(:labels, :nodes).map { |label| label[:name] } }
      end
    end
  end
end

# Finds the pull requests the commits came from, keeping the order of `commits`.
#
# Returns the pull requests for the changelog and the ones omitted by `skip_labels`.
#
def changelog_pull_requests(commits, skip_labels: CHANGELOG_SKIP_LABELS)
  origins = changelog_origins(commits)

  # Both ends of each commit, in one query: the origin a cherry-pick records, which is where the
  # change was written and reviewed, and the commit as it sits in this history, whose pull request
  # is the backport that brought it here. On the development line there are no origins and the
  # second end is the only one.
  found = changelog_associated_pull_requests(commits + origins.values)

  pull_requests = {}
  skipped = {}

  commits.each do |commit|
    carriers = found.fetch(commit, [])
    prs = origins[commit] ? found.fetch(origins[commit], []) : []

    # An origin that leads nowhere -- a commit cherry-picked from a fork, or one that went to the
    # default branch without a pull request -- falls back to the commit in this history, which is
    # at least the backport that brought it here. It is the entry itself then, not an annotation.
    backports = prs.empty? ? [] : carriers
    prs = carriers if prs.empty?

    prs.each do |pr|
      bucket = (pr[:labels] & skip_labels).empty? ? pull_requests : skipped
      entry = (bucket[pr[:number]] ||= pr.merge(backports: []))
      entry[:backports] |= backports.map { |backport| backport.slice(:number, :url) }
    end
  end

  # A backport is how a change reached this line, not a change of its own, so it belongs in the
  # entries it carried rather than beside them. It can still arrive as one: the merge commit of the
  # backport is in the history too, and carries no `-x` trailer to resolve, so it looks like an
  # ordinary commit of its own pull request. Drop the ones that annotate something.
  carried = (pull_requests.each_value.to_a + skipped.each_value.to_a).flat_map { |pr| pr[:backports] }
  carried = carried.map { |backport| backport[:number] }.uniq
  carried.each { |number| pull_requests.delete(number) }

  [pull_requests.values, skipped.values]
end

# Fetches the details that help classifying the pull requests: the changed files and the body.
#
def changelog_pull_request_details(pull_requests)
  pull_requests.each_slice(50).flat_map do |slice|
    aliases = slice.map do |pr|
      <<~GRAPHQL
        p#{pr[:number]}: pullRequest(number: #{pr[:number]}) {
          body
          author { login }
          files(first: 100) {
            nodes { path }
            pageInfo { hasNextPage }
          }
        }
      GRAPHQL
    end

    details = changelog_graphql(aliases.join("\n"))

    slice.map do |pr|
      detail = details[:"p#{pr[:number]}"] or next pr

      pr.merge(
        author: detail.dig(:author, :login),
        # The body is a hint for writing the changelog, not a copy source. Keep it short.
        body: detail[:body].to_s.strip.slice(0, 1000),
        files: detail.dig(:files, :nodes).map { |file| file[:path] },
        files_truncated: detail.dig(:files, :pageInfo, :hasNextPage)
      )
    end
  end
end

# Reports the pull requests omitted by their label, so that they do not disappear silently.
#
def warn_skipped_pull_requests(skipped, skip_labels)
  return if skipped.empty?

  numbers = skipped.map { |pr| "##{pr[:number]}" }
  numbers = numbers.take(20).push("and #{numbers.size - 20} more") if numbers.size > 20

  $stderr.puts
  $stderr.puts "  (⏭️  Skipped #{skipped.size} pull request(s) labeled #{skip_labels.map { |label| "`#{label}`" }.join(" or ")}: #{numbers.join(", ")})"
end

# The links of one changelog entry: the pull request the change was written in, and on a release
# branch the backport that carried it onto the line.
#
# The second link is what keeps a backported entry from reading as a mistake. Its first link is a
# pull request against the development line, so the same link is listed again when that line ships,
# and nothing else tells the two occurrences apart.
#
def changelog_links(pr)
  links = ["[##{pr[:number]}](#{pr[:url]})"]
  links.concat(pr[:backports].to_a.map { |backport| "Backported in [##{backport[:number]}](#{backport[:url]})" })
  links.join(", ")
end

# Prints the changelog template listing the pull requests merged between `from` and `HEAD`.
#
# The changelog goes to STDOUT and everything else goes to STDERR, so that the output can be
# piped to another command: `rake gem:changelog | pbcopy`
#
def print_changelog(from, paths: [], skip_labels: CHANGELOG_SKIP_LABELS)
  $stderr.puts "🔍 Finding pull requests merged between `#{from}` and `HEAD`..."

  commits = changelog_commits(from, paths: paths)
  if commits.empty?
    $stderr.puts "  (🤔 There is no commit after `#{from}`.)"
    return
  end

  pull_requests, skipped = changelog_pull_requests(commits, skip_labels: skip_labels)

  if pull_requests.empty?
    $stderr.puts "  (🤔 No pull request is associated to the commits after `#{from}`.)"
  else
    $stderr.puts
    pull_requests.each do |pr|
      puts "* #{pr[:title]} (#{changelog_links(pr)})"
    end
    $stdout.flush
  end

  warn_skipped_pull_requests(skipped, skip_labels)
end

# Prints the same pull requests as `print_changelog` as JSON, with the details that help
# classifying them into the sections of CHANGELOG.md.
#
# This is the input for the release automation, so it always prints a valid JSON document.
#
def print_changelog_json(from, paths: [], skip_labels: CHANGELOG_SKIP_LABELS)
  require "json"

  $stderr.puts "🔍 Finding pull requests merged between `#{from}` and `HEAD`..."

  commits = changelog_commits(from, paths: paths)
  pull_requests, skipped = changelog_pull_requests(commits, skip_labels: skip_labels)
  pull_requests = changelog_pull_request_details(pull_requests)

  $stderr.puts "  (📋 #{pull_requests.size} pull request(s))"

  puts JSON.pretty_generate(
    {
      from: from,
      to: "HEAD",
      pull_requests: pull_requests,
      skipped: skipped
    }
  )
  $stdout.flush

  warn_skipped_pull_requests(skipped, skip_labels)
end

namespace :gem do
  # The gem is developed in the whole repository except the Rust crate, which has its own release
  # cycle. Note that this is an *exclusion*, not a list of the directories shipped in the gem:
  # changes in `test/` or `.github/` are part of the gem's changelog too.
  # A constant defined in a `namespace` block is a top-level constant, so it needs the prefix.
  GEM_CHANGELOG_PATHS = [".", ":(exclude)rust"]

  # The tags a release proper starts *after*, rather than at.
  GEM_PRERELEASE_TAGS = ["v*.pre*", "v*.dev*"]

  # Where the changelog of the release being prepared starts, derived from `RBS::VERSION`:
  #
  # * `X.Y.Z.pre.N` documents what changed since `X.Y.Z.pre.N-1`, so it starts from the latest tag.
  # * `X.Y.Z` documents the whole cycle, the prereleases included, so it skips the prerelease tags
  #   in between and starts from the previous release proper.
  #
  # This is the step that is easy to get wrong by hand: on a release proper the latest tag is a
  # prerelease, so the obvious default would produce only the tail of the cycle. Passing a version
  # explicitly overrides all of it.
  #
  def changelog_base(version)
    excluded = Gem::Version.new(RBS::VERSION).prerelease? ? [] : GEM_PRERELEASE_TAGS
    resolve_changelog_base(version, tag_glob: "v*", exclude_globs: excluded)
  end

  desc "Generate changelog template from GH pull requests merged since the previous release"
  task :changelog, [:version] do |_task, args|
    print_changelog(changelog_base(args[:version]), paths: GEM_CHANGELOG_PATHS)
  end

  namespace :changelog do
    desc "Print the pull requests of `gem:changelog` as JSON, with the changed files and body of each"
    task :json, [:version] do |_task, args|
      print_changelog_json(changelog_base(args[:version]), paths: GEM_CHANGELOG_PATHS)
    end
  end

  # There are three kinds of release: `X.Y.Z`, `X.Y.Z.pre.N`, and `X.Y.Z.dev.N`. The
  # `.dev.N` ones are cut from the development line for people who need a specific
  # change early; they are not written up in the changelog, so there are no notes to
  # publish and nothing worth announcing.
  def dev_release?(version)
    Gem::Version.new(version).segments.include?("dev")
  end

  # The body of the topmost section of CHANGELOG.md, which is the release being
  # prepared, minus its own heading.
  #
  # The encoding is explicit because the default external encoding follows the
  # locale, and the changelog is not ASCII.
  #
  def changelog_section(version)
    content = File.read(File.join(__dir__, "CHANGELOG.md"), encoding: Encoding::UTF_8)
    section = content.scan(/^## \d.*?(?=^## \d)/m)[0] or raise "🚨 Cannot find a release section in CHANGELOG.md"
    heading, _, body = section.partition("\n")
    heading.include?(version) or raise "🚨 CHANGELOG.md starts with `#{heading.strip}`, which is not #{version}"
    body.strip
  end

  desc "Check that the working tree is ready to be released as the given version"
  task :check_release, [:version] do |_task, args|
    version = args[:version] or raise "🚨 Pass the version being released: `rake 'gem:check_release[4.1.2]'`"
    Gem::Version.correct?(version) or raise "🚨 `#{version}` is not a version number."

    # The version being released and the version the commit declares are stated
    # separately -- one by whoever starts the release, one by the commit itself --
    # so that releasing the wrong commit, or releasing the right one under the wrong
    # name, fails here rather than on RubyGems.
    version == RBS::VERSION or
      raise "🚨 Releasing #{version}, but this commit declares `RBS::VERSION = #{RBS::VERSION.inspect}`."

    if dev_release?(version)
      puts "✅ #{version} is the version of this commit. It is a dev release, so CHANGELOG.md is not checked."
    else
      changelog_section(version)
      puts "✅ #{version} is the version of this commit, and CHANGELOG.md documents it."
    end
  end

  desc "Create and push the `vX.Y.Z` tag for RBS::VERSION"
  task :tag do
    tag = "v#{RBS::VERSION}"

    # Annotated, so that the tag carries its own author and date rather than
    # borrowing the tagged commit's.
    sh "git", "tag", "--annotate", "--message", "RBS #{RBS::VERSION}", tag
    sh "git", "push", "origin", tag

    puts "🏷️  Pushed #{tag}."
  end

  desc "Publish the GitHub release for RBS::VERSION, unless it is a `.dev.` version"
  task :gh_release do
    require "open3"

    version = Gem::Version.new(RBS::VERSION)
    major, minor, *_ = RBS::VERSION.split(".")
    tag = "v#{RBS::VERSION}"

    if dev_release?(RBS::VERSION)
      puts "⏭️  #{RBS::VERSION} is a dev release, so there is no GitHub release to publish."
      next
    end

    # The release is created against an existing tag, so that the artifacts and the
    # notes describe a commit that is already immutable.
    _, status = Open3.capture2("git", "rev-parse", "--verify", "--quiet", "#{tag}^{commit}")
    raise "🚨 No such tag: `#{tag}`. Tag the release before creating the GitHub release." unless status.success?

    notes = <<~NOTES
      [Release note](https://github.com/ruby/rbs/wiki/Release-Note-#{major}.#{minor})

      #{changelog_section(RBS::VERSION)}
    NOTES

    # Published rather than drafted: the notes are the changelog section that was
    # already reviewed in the release pull request, so there is nothing left to edit.
    command = [
      "gh", "release", "create", tag,
      "--title=#{RBS::VERSION}",
      "--notes=#{notes}"
    ]
    command << "--prerelease" if version.prerelease?

    output, status = Open3.capture2(*command)
    raise "🚨 `gh release create` failed: #{status.inspect}" unless status.success?

    puts "📝 Released #{tag}: #{output.chomp}"
  end
end

desc "Compile extension without C23 extensions"
task :compile_c99 do
  ENV["TEST_NO_C23"] = "true"
  Rake::Task[:"compile"].invoke
ensure
  ENV.delete("TEST_NO_C23")
end

task :prepare_bench do
  ENV.delete("DEBUG")
  Rake::Task[:"clobber"].invoke
  Rake::Task[:"templates"].invoke
  Rake::Task[:"compile"].invoke
end

task :prepare_profiling do
  ENV["DEBUG"] = "1"
  Rake::Task[:"clobber"].invoke
  Rake::Task[:"templates"].invoke
  Rake::Task[:"compile"].invoke
end

namespace :wasm do
  WASM_DIR = File.expand_path("wasm", __dir__)
  WASM_OUTPUT = File.join(WASM_DIR, "rbs_parser.wasm")

  # The parser under src/ is plain, self-contained C with no dependency on the
  # Ruby C API, so it can be compiled to WebAssembly as-is. The only extra
  # translation unit is the entry-point shim under wasm/.
  def wasm_source_files
    Dir.glob(File.join(__dir__, "src/**/*.c")).sort + [File.join(WASM_DIR, "rbs_wasm.c")]
  end

  # Locate the clang shipped with the WASI SDK.
  #
  # The system clang can target wasm32, but the WASI SDK additionally provides
  # the wasi-libc sysroot and the wasm32 compiler-rt builtins that the link
  # step needs, so we require it explicitly.
  def wasi_clang
    sdk = ENV["WASI_SDK_PATH"]
    if sdk.nil? || sdk.empty?
      raise <<~MSG
        WASI_SDK_PATH is not set.

        Install the WASI SDK from https://github.com/WebAssembly/wasi-sdk/releases
        and point WASI_SDK_PATH at the extracted directory, for example:

            export WASI_SDK_PATH=/opt/wasi-sdk
            rake wasm:build
      MSG
    end

    clang = File.join(sdk, "bin", "clang")
    raise "clang not found at #{clang} (is WASI_SDK_PATH correct?)" unless File.executable?(clang)

    clang
  end

  desc "Build the RBS parser as a WebAssembly module (requires WASI_SDK_PATH)"
  task :build do
    # `-DNDEBUG` compiles out `RBS_ASSERT`, the same way ext/rbs_extension does
    # for the MRI extension. The assertions sit in the lexer and the constant
    # pool, so keeping them costs about 20% of parse time; set `DEBUG=1` to keep
    # them when debugging the module itself.
    debug_flags = ENV["DEBUG"] ? [] : ["-DNDEBUG"]

    mkdir_p WASM_DIR
    sh wasi_clang,
       "--target=wasm32-wasip1",
       # No `main`; the host calls `_initialize` and then the exported functions.
       "-mexec-model=reactor",
       "-std=gnu11",
       "-O2",
       *debug_flags,
       "-Wno-unused-parameter",
       "-I#{File.join(__dir__, "include")}",
       "-o", WASM_OUTPUT,
       *wasm_source_files
    puts "Built #{WASM_OUTPUT}"
  end

  desc "Build and smoke-test the WebAssembly module (requires wasmtime)"
  task :check => :build do
    wasmtime = ENV["WASMTIME"] || "wasmtime"

    # `rbs_wasm_selftest` parses a small fixed signature and returns 1 on
    # success. `--invoke` prints the return value to stdout.
    output = IO.popen([wasmtime, "run", "--invoke", "rbs_wasm_selftest", WASM_OUTPUT], err: File::NULL, &:read).to_s.strip

    if output == "1"
      puts "WebAssembly selftest passed."
    else
      raise "WebAssembly selftest failed: rbs_wasm_selftest returned #{output.inspect} (expected \"1\")"
    end
  end

  # Where the runtime looks for the module by default (see RBS::WASM::Runtime).
  JRUBY_WASM_DIR = File.expand_path("lib/rbs/wasm", __dir__)

  desc "Download the Chicory/ASM jars into the local Maven repository (~/.m2). Run on JRuby."
  task :install_jars do
    # Resolves the `jar` requirements from rbs.gemspec via Maven and downloads
    # them (and their transitive deps) into ~/.m2, the same way `gem install`
    # does; the jars are not copied into the gem. The platform is forced to java
    # because Jars::Installer skips non-java gems, and write_require_file is false
    # because lib/rbs_jars.rb is hand-maintained (the generator mangles the
    # `com.dylibso.chicory:runtime` artifact id).
    require "jars/installer"
    spec = Gem::Specification.load("rbs.gemspec")
    spec.platform = "java"
    Jars::Installer.new(spec).install_jars(write_require_file: false)
  end

  desc "Build rbs_parser.wasm and copy it next to RBS::WASM::Runtime"
  task :jruby_setup => [:build] do
    cp WASM_OUTPUT, File.join(JRUBY_WASM_DIR, "rbs_parser.wasm")
    puts "rbs_parser.wasm is ready under #{JRUBY_WASM_DIR}"
  end
end

namespace :rust do
  namespace :rbs do
    RUST_DIR = File.expand_path("rust", __dir__)
    RBS_VERSION_FILE = File.join(RUST_DIR, "rbs_version")

    VENDOR_TARGETS = {
      "ruby-rbs-sys" => %w[include src],
      "ruby-rbs" => %w[config.yml],
    }

    desc "Sync vendored RBS source from the pinned version"
    task :sync do
      unless File.exist?(RBS_VERSION_FILE)
        raise "#{RBS_VERSION_FILE} not found. Run `rake rust:rbs:pin[VERSION]` first."
      end

      version = File.read(RBS_VERSION_FILE).strip
      raise "#{RBS_VERSION_FILE} is empty" if version.empty?

      puts "Syncing vendor/rbs/ from #{version}..."

      VENDOR_TARGETS.each do |crate, entries|
        vendor_dir = File.join(RUST_DIR, crate, "vendor", "rbs")

        puts "  Copying files for #{crate}:"
        chmod_R "u+w", vendor_dir, verbose: false if File.exist?(vendor_dir)
        rm_rf vendor_dir, verbose: false
        mkdir_p vendor_dir, verbose: false

        entries.each do |entry|
          target = File.join(vendor_dir, entry)

          # Extract the entry from the pinned git tag using git archive
          IO.popen(["git", "archive", "--format=tar", version, "--", entry], "rb") do |tar|
            IO.popen(["tar", "xf", "-", "-C", vendor_dir], "wb") do |extract|
              IO.copy_stream(tar, extract)
            end
          end

          raise "Failed to extract #{entry} from #{version}" unless File.exist?(target)
          puts "    #{entry}"
        end

        # Make files read-only to prevent accidental edits
        chmod_R "a-w", vendor_dir, verbose: false
      end

      puts "📦 Synced vendor/rbs/ from #{version} (read-only)"
    end

    desc "Pin a specific RBS version for Rust crates (e.g., rake rust:rbs:pin[v4.0.3])"
    task :pin, [:version] do |_t, args|
      version = args[:version] or raise "Usage: rake rust:rbs:pin[VERSION]"

      # Verify the tag exists
      unless system("git", "rev-parse", "--verify", "#{version}^{commit}", out: File::NULL, err: File::NULL)
        raise "Tag #{version} not found"
      end

      File.write(RBS_VERSION_FILE, "#{version}\n")
      puts "📌 Pinned RBS version to #{version}"

      Rake::Task["rust:rbs:sync"].invoke
    end

    desc "Create symlinks from vendor/rbs/ to the repository root (for development/CI)"
    task :symlink do
      VENDOR_TARGETS.each do |crate, entries|
        vendor_dir = File.join(RUST_DIR, crate, "vendor", "rbs")

        puts "Setting up symlinks for #{crate}..."
        entries.each do |entry|
          puts "  #{entry} -> repository root"
        end

        chmod_R "u+w", vendor_dir, verbose: false if File.exist?(vendor_dir)
        rm_rf vendor_dir, verbose: false
        mkdir_p vendor_dir, verbose: false

        entries.each do |entry|
          ln_s File.join("..", "..", "..", "..", entry), File.join(vendor_dir, entry), verbose: false
        end
      end

      puts "🔗 Symlinked vendor/rbs/ to repository root"
    end
  end

  namespace :publish do
    def self.prepare_publish_branch(crate_name)
      dry_run = ENV["RBS_RUST_PUBLISH_DRY_RUN"]

      version_file = File.join(RUST_DIR, "rbs_version")

      unless File.exist?(version_file)
        raise "#{version_file} not found. Run `rake rust:rbs:pin[VERSION]` first."
      end

      rbs_version = File.read(version_file).strip
      raise "#{version_file} is empty" if rbs_version.empty?

      crate_version = File.read(File.join(RUST_DIR, crate_name, "Cargo.toml"))[/^version\s*=\s*"(.+)"/, 1]
      release_branch = "rust/release-#{crate_name}-#{Time.now.strftime('%Y%m%d%H%M%S')}"

      puts "=" * 60
      puts "Rust crate publish: #{crate_name}#{dry_run ? " (DRY RUN)" : ""}"
      puts "=" * 60
      puts "  RBS source version:  #{rbs_version}"
      puts "  #{crate_name}:        #{crate_version} (tag: #{crate_name}-v#{crate_version})"
      puts "  Release branch:      #{release_branch}"
      puts "=" * 60

      # Check that vendor dirs contain real files, not symlinks
      entries = VENDOR_TARGETS.fetch(crate_name)
      entries.each do |entry|
        path = File.join(RUST_DIR, crate_name, "vendor", "rbs", entry)
        if File.symlink?(path)
          raise "#{path} is a symlink. Run `rake rust:rbs:sync` first."
        end
        unless File.exist?(path)
          raise "#{path} does not exist. Run `rake rust:rbs:sync` first."
        end
      end

      # Ensure working tree is clean before publishing
      unless `git status --porcelain`.strip.empty?
        raise "💢 Working tree is dirty. Please commit or stash your changes before publishing."
      end

      # Create a release branch with vendor files committed
      original_branch = `git rev-parse --abbrev-ref HEAD`.strip

      sh "git", "checkout", "-b", release_branch, verbose: false
      vendor_path = File.join("rust", crate_name, "vendor", "rbs")
      sh "git", "add", "-f", vendor_path, verbose: false
      sh "git", "commit", "-m", "Publish #{crate_name} (RBS #{rbs_version})", verbose: false

      [dry_run, crate_version, original_branch]
    end

    desc "Publish ruby-rbs-sys crate to crates.io (set RBS_RUST_PUBLISH_DRY_RUN=1 for dry-run only)"
    task :"ruby-rbs-sys" do
      crate_name = "ruby-rbs-sys"
      dry_run, crate_version, original_branch = prepare_publish_branch(crate_name)

      begin
        puts "🔰 Dry-run publishing..."

        Dir.chdir(File.join(RUST_DIR, crate_name)) do
          sh "cargo", "publish", "--dry-run"
        end

        puts "✅ Dry-run succeeded!"

        unless dry_run
          puts "💪 Publishing #{crate_name} for real..."

          Dir.chdir(File.join(RUST_DIR, crate_name)) do
            sh "cargo", "publish"
          end

          sh "git", "tag", "#{crate_name}-v#{crate_version}"
          sh "git", "push", "origin", "#{crate_name}-v#{crate_version}"

          puts "🎉 Published #{crate_name} successfully!"
        end
      ensure
        sh "git", "checkout", original_branch, verbose: false
      end
    end

    desc "Publish ruby-rbs crate to crates.io (set RBS_RUST_PUBLISH_DRY_RUN=1 for dry-run only)"
    task :"ruby-rbs" do
      crate_name = "ruby-rbs"
      dry_run, crate_version, original_branch = prepare_publish_branch(crate_name)

      begin
        puts "🔰 Dry-run publishing..."

        Dir.chdir(File.join(RUST_DIR, crate_name)) do
          sh "cargo", "publish", "--dry-run", "--no-verify"
        end

        puts "✅ Dry-run succeeded!"

        unless dry_run
          puts "💪 Publishing #{crate_name} for real..."

          Dir.chdir(File.join(RUST_DIR, crate_name)) do
            sh "cargo", "publish"
          end

          sh "git", "tag", "#{crate_name}-v#{crate_version}"
          sh "git", "push", "origin", "#{crate_name}-v#{crate_version}"

          puts "🎉 Published #{crate_name} successfully!"
        end
      ensure
        sh "git", "checkout", original_branch, verbose: false
      end
    end
  end
end
