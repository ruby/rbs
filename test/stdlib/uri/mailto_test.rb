require_relative "../test_helper"
require "uri"

class URI::MailToSingletonTest < Test::Unit::TestCase
  include TestHelper

  library "uri"
  testing "singleton(::URI::MailTo)"

  def test_EMAIL_REGEXP
    assert_const_type "::Regexp", "URI::MailTo::EMAIL_REGEXP"
  end

  def test_build
    assert_send_type "(::Array[ ::String ]) -> ::URI::MailTo",
                     URI::MailTo, :build, ["example@example.com", "subject=subject"]
    assert_send_type "([ ::String, ::Array[ ::Array[ ::String ] ] ]) -> ::URI::MailTo",
                     URI::MailTo, :build, ["example@example.com", [["subject", "subject"]]]
    assert_send_type "(::Hash[ ::Symbol, ::String | ::Array[ ::Array[ ::String ] ] ]) -> ::URI::MailTo",
                     URI::MailTo, :build, { to: "example@example.com", headers: "subject=subject" }
  end
end

class URI::MailToTest < Test::Unit::TestCase
  include TestHelper

  library "uri"
  testing "::URI::MailTo"

  def test_headers
    assert_send_type "() -> ::Array[[ ::String, ::String ]]",
                     URI::MailTo.build(["example@example.com", "subject=subject"]), :headers
  end

  def test_headers=
    assert_send_type "(::String) -> ::String",
                     URI::MailTo.build(["example@example.com", "subject=subject"]), :headers=, "subject=subject2"
  end

  def test_to
    assert_send_type "() -> ::String",
                     URI::MailTo.build(["example@example.com", "subject=subject"]), :to
  end

  def test_to=
    assert_send_type "(::String) -> ::String",
                     URI::MailTo.build(["example@example.com", "subject=subject"]), :to=, "example2@example.com"
  end

  def test_to_mailtext
    assert_send_type "() -> ::String",
                     URI::MailTo.build(["example@example.com", "subject=subject"]), :to_mailtext
  end

  def test_to_rfc822text
    assert_send_type "() -> ::String",
                     URI::MailTo.build(["example@example.com", "subject=subject"]), :to_rfc822text
  end
end
