require_relative "../test_helper"

class GemSingletonTest < Test::Unit::TestCase
  include TypeAssertions

  class HashLike
    def initialize(pairs)
      @pairs = pairs
    end

    def each_pair(&block)
      @pairs.each(&block)
    end
  end

  testing "singleton(::Gem)"

  def test_activated_gem_paths
    assert_send_type  "() -> Integer",
                      Gem, :activated_gem_paths
  end

  def test_add_to_load_path
    assert_send_type  "(*String) -> Array[String]",
                      Gem, :add_to_load_path, "foo"
  end

  def test_bin_path
    assert_send_type  "(String, String) -> String",
                      Gem, :bin_path, "rake", "rake"
    assert_send_type  "(String, String, Array[Gem::Requirement]) -> String",
                      Gem, :bin_path, "rake", "rake", [Gem::Requirement.default]
  end

  def test_binary_mode
    assert_send_type  "() -> String",
                      Gem, :binary_mode
  end

  def test_bindir
    assert_send_type  "() -> String",
                      Gem, :bindir
    assert_send_type  "(String) -> String",
                      Gem, :bindir, "foo"
  end

  def test_cache_home
    assert_send_type  "() -> String",
                      Gem, :cache_home
  end

  def test_clear_default_specs
    assert_send_type  "() -> void",
                      Gem, :clear_default_specs
  end

  def test_clear_paths
    assert_send_type  "() -> void",
                      Gem, :clear_paths
  end

  def test_config_file
    assert_send_type  "() -> String",
                      Gem, :config_file
  end

  def test_config_home
    assert_send_type  "() -> String",
                      Gem, :config_home
  end

  def test_configuration
    assert_send_type  "() -> Gem::ConfigFile",
                      Gem, :configuration
  end

  def test_configuration=
    assert_send_type  "(Gem::ConfigFile) -> Gem::ConfigFile",
                      Gem, :configuration=, Gem::ConfigFile.new([""])
  end

  def test_data_home
    assert_send_type  "() -> String",
                      Gem, :data_home
  end

  def test_default_bindir
    assert_send_type  "() -> String",
                      Gem, :default_bindir
  end

  def test_default_cert_path
    assert_send_type  "() -> String",
                      Gem, :default_cert_path
  end

  def test_default_dir
    assert_send_type  "() -> String",
                      Gem, :default_dir
  end

  def test_default_exec_format
    assert_send_type  "() -> String",
                      Gem, :default_exec_format
  end

  def test_default_ext_dir_for
    assert_send_type  "(String) -> String?",
                      Gem, :default_ext_dir_for, "foo"
  end

  def test_default_key_path
    assert_send_type  "() -> String",
                      Gem, :default_key_path
  end

  def test_default_path
    assert_send_type  "() -> Array[String]",
                      Gem, :default_path
  end

  def test_default_rubygems_dirs
    assert_send_type  "() -> Array[String]?",
                      Gem, :default_rubygems_dirs
  end

  def test_default_sources
    assert_send_type  "() -> Array[String]",
                      Gem, :default_sources
  end

  def test_default_spec_cache_dir
    assert_send_type  "() -> String",
                      Gem, :default_spec_cache_dir
  end

  def test_default_specifications_dir
    assert_send_type  "() -> String",
                      Gem, :default_specifications_dir
  end

  def test_deflate
    assert_send_type  "(String) -> String",
                      Gem, :deflate, "foo"
  end

  def test_dir
    assert_send_type  "() -> String",
                      Gem, :dir
  end

  def test_disable_system_update_message
    assert_send_type  "() -> String?",
                      Gem, :disable_system_update_message
  end

  def test_disable_system_update_message=
    assert_send_type  "(nil) -> nil",
                      Gem, :disable_system_update_message=, nil
    assert_send_type  "(String) -> String",
                      Gem, :disable_system_update_message=, "foo"
  end

  def test_done_installing
    assert_send_type  "() { (Gem::DependencyInstaller, Array[Gem::Specification]) -> [ Gem::DependencyInstaller, Array[Gem::Specification] ] } -> Array[Proc]",
                      Gem, :done_installing do |installer, spec| [installer, spec] end
  end

  def test_done_installing_hooks
    assert_send_type  "() -> Array[Proc?]",
                      Gem, :done_installing_hooks
  end

  def test_ensure_default_gem_subdirectories
    Dir.mktmpdir do |dir|
      assert_send_type  "() -> Array[String]",
                        Gem, :ensure_default_gem_subdirectories
      assert_send_type  "(String) -> Array[String]",
                        Gem, :ensure_default_gem_subdirectories, dir
      assert_send_type  "(String, Integer) -> Array[String]",
                        Gem, :ensure_default_gem_subdirectories, dir, 0600
      assert_send_type  "(String, String) -> Array[String]",
                        Gem, :ensure_default_gem_subdirectories, dir, "u=wrx"
    end
  end

  def test_ensure_gem_subdirectories
    Dir.mktmpdir do |dir|
      assert_send_type  "() -> Array[String]",
                        Gem, :ensure_gem_subdirectories
      assert_send_type  "(String) -> Array[String]",
                        Gem, :ensure_gem_subdirectories, dir
      assert_send_type  "(String, Integer) -> Array[String]",
                        Gem, :ensure_gem_subdirectories, dir, 0600
      assert_send_type  "(String, String) -> Array[String]",
                        Gem, :ensure_gem_subdirectories, dir, "u=wrx"
    end
  end

  def test_env_requirement
    assert_send_type  "(String) -> Gem::Requirement",
                      Gem, :env_requirement, ""
  end

  def test_find_config_file
    assert_send_type  "() -> String",
                      Gem, :find_config_file
  end

  def test_find_files
    assert_send_type  "(String) -> Array[String]",
                      Gem, :find_files, "fileutils.rb"
    assert_send_type  "(String, bool) -> Array[String]",
                      Gem, :find_files, "fileutils.rb", true
  end

  def test_find_latest_files
    assert_send_type  "(String) -> Array[String]",
                      Gem, :find_latest_files, "fileutils.rb"
    assert_send_type  "(String, bool) -> Array[String]",
                      Gem, :find_latest_files, "fileutils.rb", false
  end

  def test_find_unresolved_default_spec
    assert_send_type  "(String) -> Gem::Specification?",
                      Gem, :find_unresolved_default_spec, "fileutils.rb"
  end

  def test_finish_resolve
    assert_send_type  "() -> Array[untyped]",
                      Gem, :finish_resolve
    assert_send_type  "(Gem::RequestSet) -> Array[untyped]",
                      Gem, :finish_resolve, Gem::RequestSet.new(Gem::Dependency.new("test-unit"))
  end

  def test_gemdeps
    assert_send_type  "() -> Gem::RequestSet::GemDependencyAPI?",
                      Gem, :gemdeps
  end

  def test_host
    assert_send_type  "() -> String",
                      Gem, :host
  end

  def test_host=
    assert_send_type  "(String) -> String",
                      Gem, :host=, "foo"
  end

  def test_install
    omit "due to side-effect"
    assert_send_type  "(String, Gem::Requirement) -> Array[Gem::Specification]",
                      Gem, :install, "", Gem::Requirement.default
  end

  def test_java_platform?
    assert_send_type  "() -> bool",
                      Gem, :java_platform?
  end

  def test_latest_rubygems_version
    assert_send_type  "() -> Gem::Version",
                      Gem, :latest_rubygems_version
  end

  def test_latest_spec_for
    assert_send_type  "(String) -> nil",
                      Gem, :latest_spec_for, ""
    assert_send_type  "(String) -> Gem::Specification",
                      Gem, :latest_spec_for, "fileutils"
  end

  def test_latest_version_for
    assert_send_type  "(String) -> nil",
                      Gem, :latest_version_for, ""
    assert_send_type  "(String) -> Gem::Version",
                      Gem, :latest_version_for, "fileutils"
  end

  def test_load_env_plugins
    assert_send_type  "() -> Array[String]",
                      Gem, :load_env_plugins
  end

  def test_load_path_insert_index
    assert_send_type  "() -> Integer",
                      Gem, :load_path_insert_index
  end

  def test_load_plugins
    assert_send_type  "() -> Array[String]",
                      Gem, :load_plugins
  end

  def test_load_yaml
    assert_send_type  "() -> bool?",
                      Gem, :load_yaml
  end

  def test_loaded_specs
    omit "due to Bundler::StubSpecification returns"
    assert_send_type  "() -> Hash[String, Gem::BasicSpecification]",
                      Gem, :loaded_specs
  end

  def test_location_of_caller
    assert_send_type  "() -> [ String, Integer ]",
                      Gem, :location_of_caller
    assert_send_type  "(Integer) -> [ String, Integer ]",
                      Gem, :location_of_caller, 0
  end

  def test_marshal_version
    assert_send_type  "() -> String",
                      Gem, :marshal_version
  end

  def test_needs
    assert_send_type  "() { (Gem::RequestSet) -> Gem::RequestSet } -> Array[untyped]",
                      Gem, :needs do |rs| rs end
  end

  def test_operating_system_defaults
    assert_send_type  "() -> Hash[String, String]",
                      Gem, :operating_system_defaults
  end

  def test_path
    assert_send_type  "() -> Array[String]",
                      Gem, :path
  end

  def test_path_separator
    assert_send_type  "() -> String",
                      Gem, :path_separator
  end

  def test_paths
    assert_send_type  "() -> Gem::PathSupport",
                      Gem, :paths
  end

  def test_paths=
    assert_send_type  "(GemSingletonTest::HashLike[String, String?]) -> Array[String]",
                      Gem, :paths=, HashLike.new([["k1", "v1"], ["k2", nil]])
  end

  def test_platform_defaults
    assert_send_type  "() -> Hash[String, String]",
                      Gem, :platform_defaults
  end

  def test_platforms
    assert_send_type  "() -> Array[String | Gem::Platform]",
                      Gem, :platforms
  end

  def test_platforms=
    assert_send_type  "(Array[String | Gem::Platform]) -> Array[String | Gem::Platform]",
                      Gem, :platforms=, Gem.platforms
  end

  def test_plugin_suffix_pattern
    assert_send_type  "() -> String",
                      Gem, :plugin_suffix_pattern
  end

  def test_plugin_suffix_regexp
    assert_send_type  "() -> Regexp",
                      Gem, :plugin_suffix_regexp
  end

  def test_plugindir
    assert_send_type  "() -> String",
                      Gem, :plugindir
    assert_send_type  "(String) -> String",
                      Gem, :plugindir, "foo"
  end

  def test_post_build
    assert_send_type  "() { (Gem::Installer) -> Gem::Installer } -> Array[Proc]",
                      Gem, :post_build do |installer| installer end
  end

  def test_post_build_hooks
    assert_send_type  "() -> Array[Proc]",
                      Gem, :post_build_hooks
  end

  def test_post_install
    assert_send_type  "() { (Gem::Installer) -> Gem::Installer } -> Array[Proc]",
                      Gem, :post_install do |installer| installer end
  end

  def test_post_install_hooks
    assert_send_type  "() -> Array[Proc]",
                      Gem, :post_install_hooks
  end

  def test_post_reset
    assert_send_type  "() { () -> Integer } -> Array[Proc]",
                      Gem, :post_reset do 1 end
  end

  def test_post_reset_hooks
    assert_send_type  "() -> Array[Proc?]",
                      Gem, :post_reset_hooks
  end

  def test_post_uninstall
    assert_send_type  "() { (Gem::Uninstaller) -> Gem::Uninstaller } -> Array[Proc]",
                      Gem, :post_uninstall do |uninstaller| uninstaller end
  end

  def test_post_uninstall_hooks
    assert_send_type  "() -> Array[Proc?]",
                      Gem, :post_uninstall_hooks
  end

  def test_pre_install
    assert_send_type  "() { (Gem::Installer) -> Gem::Installer } -> Array[Proc]",
                      Gem, :pre_install do |installer| installer end
  end

  def test_pre_install_hooks
    assert_send_type  "() -> Array[Proc?]",
                      Gem, :pre_install_hooks
  end

  def test_pre_reset
    assert_send_type  "() { () -> String } -> Array[Proc]",
                      Gem, :pre_reset do "" end
  end

  def test_pre_reset_hooks
    assert_send_type  "() -> Array[Proc?]",
                      Gem, :pre_reset_hooks
  end

  def test_pre_uninstall
    assert_send_type  "() { (Gem::Uninstaller) -> Gem::Uninstaller } -> Array[Proc]",
                      Gem, :pre_uninstall do |uninstaller| uninstaller end
  end

  def test_pre_uninstall_hooks
    assert_send_type  "() -> Array[Proc?]",
                      Gem, :pre_uninstall_hooks
  end

  def test_prefix
    assert_send_type  "() -> String?",
                      Gem, :prefix
  end

  def test_read_binary
    assert_send_type  "(String) -> String",
                      Gem, :read_binary, File.expand_path(__FILE__)
  end

  def test_refresh
    assert_send_type  "() -> Array[Proc]",
                      Gem, :refresh
  end

  def test_register_default_spec
    assert_send_type  "(Gem::Specification) -> Array[String]",
                      Gem, :register_default_spec, Gem::Specification.new
  end

  def test_ruby
    assert_send_type  "() -> String",
                      Gem, :ruby
  end

  def test_ruby_api_version
    assert_send_type  "() -> String",
                      Gem, :ruby_api_version
  end

  def test_ruby_engine
    assert_send_type  "() -> String",
                      Gem, :ruby_engine
  end

  def test_ruby_version
    assert_send_type  "() -> Gem::Version",
                      Gem, :ruby_version
  end

  def test_rubygems_version
    assert_send_type  "() -> Gem::Version",
                      Gem, :rubygems_version
  end

  def test_source_date_epoch
    assert_send_type  "() -> Time",
                      Gem, :source_date_epoch
  end

  def test_source_date_epoch_string
    assert_send_type  "() -> String",
                      Gem, :source_date_epoch_string
  end

  def test_sources
    assert_send_type  "() -> Gem::SourceList",
                      Gem, :sources
  end

  def test_sources=
    assert_send_type  "(nil) -> nil",
                      Gem, :sources=, nil
    assert_send_type  "(Gem::SourceList) -> Gem::SourceList",
                      Gem, :sources=, Gem::SourceList.new
  end

  def test_spec_cache_dir
    assert_send_type  "() -> String",
                      Gem, :spec_cache_dir
  end

  def test_suffix_pattern
    assert_send_type  "() -> String",
                      Gem, :suffix_pattern
  end

  def test_suffix_regexp
    assert_send_type  "() -> Regexp",
                      Gem, :suffix_regexp
  end

  def test_suffixes
    assert_send_type  "() -> Array[String]",
                      Gem, :suffixes
  end

  def test_time
    assert_send_type  "(String) { () -> Integer } -> Integer",
                      Gem, :time, "foo" do 100 end
    assert_send_type  "(String, Integer, bool) { () -> Regexp } -> Regexp",
                      Gem, :time, "foo", 5, false do /bar/ end
  end

  def test_try_activate
    assert_send_type  "(String) -> bool",
                      Gem, :try_activate, "foo"
  end

  def test_ui
    assert_send_type  "() -> Gem::StreamUI",
                      Gem, :ui
  end

  def test_use_gemdeps
    assert_send_type  "() -> void",
                      Gem, :use_gemdeps
  end

  def test_use_paths
    assert_send_type  "(String, String) -> Hash[String, String]",
                      Gem, :use_paths, "foo", "bar"
  end

  def test_user_dir
    assert_send_type  "() -> String",
                      Gem, :user_dir
  end

  def test_user_home
    assert_send_type  "() -> String",
                      Gem, :user_home
  end

  def test_win_platform?
    assert_send_type  "() -> bool",
                      Gem, :win_platform?
  end

  def test_write_binary
    Tempfile.open do |file|
      assert_send_type  "(String, String) -> Integer",
                        Gem, :write_binary, file.path, "foo"
    end
  end
end

