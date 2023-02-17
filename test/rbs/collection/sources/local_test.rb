require "test_helper"

class RBS::Collection::Sources::LocalTest < Test::Unit::TestCase
  def test_has?
    with_local_source do |s|
      assert s.has?('ast', nil)
      refute s.has?('ast', "1.2.3.4")

      refute s.has?('rbs', nil)
    end
  end

  def test_versions
    with_local_source do |s|
      assert_equal ['2.4'], s.versions('ast')
    end
  end

  def test_manifest_of
    with_local_source do |s|
      assert_instance_of Hash, s.manifest_of('manifest', '4.5')
      assert_nil s.manifest_of('ast', '2.4')

      assert_raises do
        s.manifest_of('ast', '0.0')
      end
    end
  end

  private def source(path:)
    RBS::Collection::Sources.from_config_entry({
      'type' => 'local',
      'name' => 'the local source',
      'path' => path,
    }, base_directory: Pathname(path).dirname)
  end

  private def with_local_source
    mktmpdir do |path|
      path.join('ast/2.4').tap do |dir|
        dir.mkpath
        dir.join('ast.rbs').write('class Ast end')
      end

      path.join('manifest/4.5').tap do |dir|
        dir.mkpath
        dir.join('manifest.rbs').write('class Manifest end')
        dir.join('manifest.yaml').write(<<~YAML)
          dependencies:
            - name: logger
        YAML
      end

      yield source(path: path)
    end
  end

  private def mktmpdir
    Dir.mktmpdir do |path|
      yield Pathname(path)
    end
  end
end
