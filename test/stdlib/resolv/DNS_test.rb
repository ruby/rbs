require_relative '../test_helper'
require 'resolv'

class ResolvDNSSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library 'resolv'
  testing 'singleton(::Resolv::DNS)'

  def test_allocate_request_id
    assert_send_type  '(String, Integer) -> Integer',
      Resolv::DNS, :allocate_request_id, "localhost", 53
  end

  def test_bind_random_port
    assert_send_type  '(UDPSocket) -> void',
      Resolv::DNS, :bind_random_port, UDPSocket.new
    assert_send_type  '(UDPSocket, String) -> void',
      Resolv::DNS, :bind_random_port, UDPSocket.new, "127.0.0.1"
  end

  def test_free_request_id
    assert_send_type  '(String, Integer, Integer) -> void',
      Resolv::DNS, :free_request_id, "localhost", 53, 123
  end

  def test_open
    assert_send_type  '(Hash[Symbol, untyped]) -> Resolv::DNS',
      Resolv::DNS, :open, :nameserver => ["8.8.8.8"]
    assert_send_type  '(Hash[Symbol, untyped]) { (Resolv::DNS) -> void } -> void',
      Resolv::DNS, :open, :nameserver => ["8.8.8.8"] do |c| c; end
  rescue Errno::ECONNREFUSED
    omit "Connection refused with environmental issue"
  end

  def test_random
    assert_send_type  '(Numeric) -> Numeric',
      Resolv::DNS, :random, 2
  end
end

class ResolvDNSinstanceTest < Test::Unit::TestCase
  include TypeAssertions
  library 'resolv'
  testing '::Resolv::DNS'

  def resolv_dns(*args)
    dns = Resolv::DNS.new(*args)
    dns.lazy_initialize
    dns
  end

  def test_close
    assert_send_type "() -> void",
      resolv_dns, :close
  end

  def test_each_address
    assert_send_type "(String) { (Resolv::IPv4 | Resolv::IPv6) -> void } -> void",
      resolv_dns, :each_address, "localhost" do |c| c end
        assert_send_type "(Resolv::DNS::Name) { (Resolv::IPv4 | Resolv::IPv6) -> void } -> void",
        resolv_dns, :each_address, Resolv::DNS::Name.create("localhost") do |c| c end
  end

  def test_each_name
    assert_send_type "(String | Resolv::DNS::Name) { (Resolv::DNS::Name) -> void } -> void",
      resolv_dns, :each_name, "127.0.0.1"  do |c| c end
  end

  def test_each_resource
    assert_send_type "(String, singleton(Resolv::DNS::Query)) { (Resolv::DNS::Resource) -> void } -> void",
      resolv_dns, :each_resource, "localhost", Resolv::DNS::Resource::IN::A  do |*c| c end
    assert_send_type "(Resolv::DNS::Name, singleton(Resolv::DNS::Query)) { (Resolv::DNS::Resource) -> void } -> void",
      resolv_dns, :each_resource, Resolv::DNS::Name.create("localhost"), Resolv::DNS::Resource::IN::A  do |*c| c end
  end

  def test_extract_resources
    msg = Resolv::DNS::Message.new
    assert_send_type "(Resolv::DNS::Message, String, singleton(Resolv::DNS::Query)) { (Resolv::DNS::Resource) -> void } -> void",
      resolv_dns, :extract_resources, msg, "localhost", Resolv::DNS::Resource::IN::A do |c| c end
    assert_send_type "(Resolv::DNS::Message, Resolv::DNS::Name, singleton(Resolv::DNS::Query)) { (Resolv::DNS::Resource) -> void } -> void",
      resolv_dns, :extract_resources, msg, Resolv::DNS::Name.create("localhost"), Resolv::DNS::Resource::IN::A do |c| c end
  end

  def test_fetch_resource
    assert_send_type "(Resolv::DNS::Name, singleton(Resolv::DNS::Query)) { (Resolv::DNS::Message, Resolv::DNS::Name) -> void } -> void",
      resolv_dns, :fetch_resource, Resolv::DNS::Name.create("localhost"), Resolv::DNS::Resource::IN::A do |*c| c end
  end

  def test_getaddress
    allows_error(Resolv::ResolvError) do
      assert_send_type "(String) -> (Resolv::IPv4 | Resolv::IPv6)",
                       resolv_dns, :getaddress, "localhost"
      assert_send_type "(Resolv::DNS::Name) -> (Resolv::IPv4 | Resolv::IPv6)",
                       resolv_dns, :getaddress, Resolv::DNS::Name.create("localhost")
    end
  end

  def test_getaddresses
    assert_send_type "(String) -> Array[Resolv::IPv4 | Resolv::IPv6]",
      resolv_dns, :getaddresses, "localhost"
    assert_send_type "(Resolv::DNS::Name) -> Array[Resolv::IPv4 | Resolv::IPv6]",
      resolv_dns, :getaddresses, Resolv::DNS::Name.create("localhost")
  end

  def test_getname
    allows_error(Resolv::ResolvError) do
      assert_send_type "(String) -> Resolv::DNS::Name",
        resolv_dns, :getname, "127.0.0.1"
      assert_send_type "(Resolv::IPv4) -> Resolv::DNS::Name",
        resolv_dns, :getname, Resolv::IPv4.create("127.0.0.1")
      assert_send_type "(Resolv::DNS::Name) -> Resolv::DNS::Name",
        resolv_dns, :getname, Resolv::IPv4.create("127.0.0.1").to_name
    end
  end

  def test_getnames
    assert_send_type "(String) -> Array[Resolv::DNS::Name]",
      resolv_dns, :getnames, "127.0.0.1"
  end

  def test_getresource
    allows_error(Resolv::ResolvError) do
      assert_send_type "(String, singleton(Resolv::DNS::Query)) -> Resolv::DNS::Resource",
        resolv_dns, :getresource, "localhost", Resolv::DNS::Resource::IN::A
    end
  end

  def test_getresources
    assert_send_type "(String, singleton(Resolv::DNS::Query)) -> Array[Resolv::DNS::Resource]",
      resolv_dns, :getresources, "localhost", Resolv::DNS::Resource::IN::A
    assert_send_type "(Resolv::DNS::Name, singleton(Resolv::DNS::Query)) -> Array[Resolv::DNS::Resource]",
      resolv_dns, :getresources, Resolv::DNS::Name.create("localhost"), Resolv::DNS::Resource::IN::A
  end

  def test_make_tcp_requester
    assert_send_type "(String, Integer) -> Resolv::DNS::Requester::TCP",
      resolv_dns, :make_tcp_requester, "8.8.8.8", 53
  rescue Errno::ECONNREFUSED
    omit "Connection refused with environmental issue"
  end

  def test_make_udp_requester
    assert_send_type "() -> Resolv::DNS::Requester::ConnectedUDP",
      resolv_dns(nameserver: ["8.8.8.8"]), :make_udp_requester
    assert_send_type "() -> Resolv::DNS::Requester::UnconnectedUDP",
      resolv_dns(nameserver: ["127.0.0.1", "8.8.8.8"]), :make_udp_requester
  rescue Errno::ECONNREFUSED
      omit "Connection refused with environmental issue"
  end

  def test_timeouts=
    assert_send_type "(Integer) -> void",
    resolv_dns, :timeouts=, 5

    assert_send_type "(Array[Integer]) -> void",
    resolv_dns, :timeouts=, [5, 3, 2, 1]
  end
end

class ResolvDNSConfigSingletonTest < Test::Unit::TestCase
  include TypeAssertions
  library 'resolv'
  testing 'singleton(::Resolv::DNS::Config)'

  def test_default_config_hash
    assert_send_type  '() -> Hash[Symbol, untyped]',
      Resolv::DNS::Config, :default_config_hash
    assert_send_type  '(String) -> Hash[Symbol, untyped]',
      Resolv::DNS::Config, :default_config_hash, "/etc/resolv.conf"
  end

  def test_parse_resolv_conf
    assert_send_type  '(String) -> Hash[Symbol, untyped]',
      Resolv::DNS::Config, :parse_resolv_conf, "/etc/resolv.conf"
  end
end

class ResolvDNSConfigInstanceTest < Test::Unit::TestCase
  include TypeAssertions
  library 'resolv'
  testing '::Resolv::DNS::Config'

  def dns_config(*args)
    config = Resolv::DNS::Config.new(*args)
    config.lazy_initialize
    config
  end

  def test_generate_candidates
    assert_send_type '(String) -> Array[Resolv::DNS::Name]',
      dns_config, :generate_candidates, "localhost"
  end

  def test_generate_timeouts
   assert_send_type '() -> Array[Integer]',
    dns_config, :generate_timeouts
  end

  def test_nameserver_port
    assert_send_type '() -> Array[[String, Integer]]',
      dns_config, :nameserver_port
  end

  def test_resolv
    assert_send_type '(String) { (Resolv::DNS::Name, Integer, String, Integer) -> void } -> void',
      dns_config, :resolv, "localhost" do |*c| c ; end
  end

  def test_single?
    assert_send_type '() -> [String, Integer]?',
      dns_config, :single?
  end

  def test_timeouts=
    assert_send_type "(Integer) -> void",
      dns_config, :timeouts=, 5

    assert_send_type "(Array[Integer]) -> void",
      dns_config, :timeouts=, [5, 3, 2, 1]
  end
end

# class ResolvDNSMessageSingletonTest < Test::Unit::TestCase
#   include TypeAssertions
#   library 'resolv'
#   testing 'singleton(::Resolv::DNS::Message)'

#   def test_decode
#     assert_send_type "(String) -> Resolv::DNS::Message",
#       Resolv::DNS::Message, :decode, ""
#   end
# end

class ResolvDNSMessageInstanceTest < Test::Unit::TestCase
  include TypeAssertions
  library 'resolv'
  testing '::Resolv::DNS::Message'

  def dns_message
    msg = Resolv::DNS::Message.new(0)
    msg.add_additional("localhost", 220, Resolv::DNS::Resource::IN::A.new("127.0.0.1"))
    msg.add_answer("localhost", 220, Resolv::DNS::Resource::IN::A.new("127.0.0.1"))
    msg.add_authority("localhost", 220, Resolv::DNS::Resource::IN::A.new("127.0.0.1"))
    msg.add_question("localhost", Resolv::DNS::Resource::IN::A)
    msg
  end

  def test_eql?
    assert_send_type "(Resolv::DNS::Message) -> bool",
      dns_message, :==, Resolv::DNS::Message.new(0)
  end

  def test_add_additional
    assert_send_type "(String, Integer, Resolv::DNS::Resource) -> void",
      dns_message, :add_additional, "localhost", 220, Resolv::DNS::Resource::IN::A.new("127.0.0.1")
  end

  def test_add_answer
    assert_send_type "(String, Integer, Resolv::DNS::Resource) -> void",
      dns_message, :add_answer, "localhost", 220, Resolv::DNS::Resource::IN::A.new("127.0.0.1")
  end

  def test_add_authority
    assert_send_type "(String, Integer, Resolv::DNS::Resource) -> void",
      dns_message, :add_authority, "localhost", 220, Resolv::DNS::Resource::IN::A.new("127.0.0.1")
  end

  def test_add_question
    assert_send_type "(String, singleton(Resolv::DNS::Query)) -> void",
      dns_message, :add_question, "localhost", Resolv::DNS::Resource::IN::A
  end

  def test_each_additional
    assert_send_type "() { (Resolv::DNS::Name, Integer, Resolv::DNS::Resource) -> void } -> void",
      dns_message, :each_additional do |*c| c ; end
  end

  def test_each_answer
    assert_send_type "() { (Resolv::DNS::Name, Integer, Resolv::DNS::Resource) -> void } -> void",
      dns_message, :each_answer do |*c| c ; end
  end

  def test_each_authority
    assert_send_type "() { (Resolv::DNS::Name, Integer, Resolv::DNS::Resource) -> void } -> void",
      dns_message, :each_authority do |*c| c ; end
  end

  def test_each_question
    assert_send_type "() { (Resolv::DNS::Name, singleton(Resolv::DNS::Query)) -> void } -> void",
      dns_message, :each_question do |*c| c ; end
  end

  def test_each_resource
    assert_send_type "() { (Resolv::DNS::Name, Integer, Resolv::DNS::Resource) -> void } -> void",
      dns_message, :each_resource do |*c| c ; end
  end

  def test_encode
    assert_send_type "() -> String",
      dns_message, :encode
  end
end

class ResolvDNSMessageEncoderInstanceTest < Test::Unit::TestCase
  include TypeAssertions
  library 'resolv'
  testing '::Resolv::DNS::Message::MessageEncoder'

  def encoder
    Resolv::DNS::Message::MessageEncoder.new{}
  end

  def test_put_bytes
    assert_send_type "(String) -> void",
      encoder, :put_bytes, "a"
  end

  def test_put_label
    assert_send_type "(String) -> void",
      encoder, :put_label, "data"
  end

  def test_put_labels
    assert_send_type "(Array[String]) -> void",
      encoder, :put_labels, %w[data]
  end

  def test_put_length16
    assert_send_type "() { () -> void } -> void",
      encoder, :put_length16 do |c| c ; end
  end

  def test_put_name
    assert_send_type "(Resolv::DNS::Name) -> void",
      encoder, :put_name, Resolv::DNS::Name.create("localhost")
  end

  def test_put_pack
    assert_send_type "(String, *untyped) -> void",
      encoder, :put_pack, "C", 4
  end

  def test_put_string
    assert_send_type "(String) -> void",
      encoder, :put_string, "data"
  end

  def test_put_string_list
    assert_send_type "(Array[String]) -> void",
      encoder, :put_string_list, ["data1", "data2"]
  end
end

class ResolvDNSMessageDecoderInstanceTest < Test::Unit::TestCase
  include TypeAssertions
  library 'resolv'
  testing '::Resolv::DNS::Message::MessageDecoder'

  def decoder(data = "\u0004data\u0000")
    Resolv::DNS::Message::MessageDecoder.new(data) {}
  end

  def test_get_bytes
    assert_send_type "() -> String",
      decoder, :get_bytes
    assert_send_type "(Integer) -> String",
      decoder, :get_bytes, 2
  end

  def test_get_label
    assert_send_type "() -> Resolv::DNS::Label::Str",
      decoder, :get_label
  end

  def test_get_labels
    assert_send_type "() -> Array[Resolv::DNS::Label::Str]",
      decoder, :get_labels
  end

  def test_get_name
    assert_send_type "() -> Resolv::DNS::Name",
      decoder, :get_name
  end

  def test_get_unpack
    assert_send_type "(String) -> Array[untyped]",
      decoder, :get_unpack, "c"
  end

  def test_get_string
    assert_send_type "() -> String",
      decoder, :get_string
  end

  def test_get_rr
    assert_send_type "() -> [Resolv::DNS::Name, Integer, Resolv::DNS::Resource]",
      decoder("\x05data0\x00\x05data1\x00\xC0\x00\xC0\a"), :get_rr
  end

  def test_get_string_list
    assert_send_type "() -> Array[String]",
      decoder("\u0004data\u0000"), :get_string_list
  end
end

class ResolvDNSNameInstanceTest < Test::Unit::TestCase
  include TypeAssertions
  library 'resolv'
  testing '::Resolv::DNS::Name'

  def dns_name
    Resolv::DNS::Name.create("localhost")
  end

  def test_eql?
    assert_send_type "(Resolv::DNS::Name) -> bool",
      dns_name, :==, Resolv::DNS::Name.create("localhost2")
  end

  def test_lookup
    assert_send_type "(Integer) -> Resolv::DNS::Label::Str",
      dns_name, :[], 0
    assert_send_type "(Integer) -> nil",
      dns_name, :[], 1
  end

  def test_absolute?
    assert_send_type "() -> bool",
      dns_name, :absolute?
  end

  def test_hash
    assert_send_type "() -> Integer",
      dns_name, :hash
  end

  def test_length
    assert_send_type "() -> Integer",
      dns_name, :length
  end

  def test_subdomain_of?
    assert_send_type "(Resolv::DNS::Name) -> bool",
      dns_name, :subdomain_of?, Resolv::DNS::Name.create("localhost2")
  end
end

class ResolvDNSLabelStrInstanceTest < Test::Unit::TestCase
  include TypeAssertions
  library 'resolv'
  testing '::Resolv::DNS::Label::Str'

  def label
    Resolv::DNS::Label::Str.new("localhost")
  end

  def test_eql?
    assert_send_type "(Resolv::DNS::Label::Str) -> bool",
      label, :==, Resolv::DNS::Label::Str.new("localhost2")
  end

  def test_downcase
    assert_send_type "() -> String",
      label, :downcase
  end

  def test_string
    assert_send_type "() -> String",
      label, :string
  end

  def test_hash
    assert_send_type "() -> Integer",
      label, :hash
  end
end


class ResolvDNSRequesterInstanceTest < Test::Unit::TestCase
  include TypeAssertions
  library 'resolv'
  testing '::Resolv::DNS::Requester'

  def requester
    Resolv::DNS::Requester.new
  end

  def test_close
    assert_send_type "() -> void",
      requester, :close
  end
end
