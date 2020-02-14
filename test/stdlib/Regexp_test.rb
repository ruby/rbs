require_relative "test_helper"

class RegexpTest < StdlibTest
  target Regexp
  using hook.refinement

  def test_new
    Regexp.new('dog')
    Regexp.new('dog', option = Regexp::IGNORECASE)
    Regexp.new('dog', code = 'n')
    Regexp.new('dog', option = Regexp::IGNORECASE, code = 'n')
    Regexp.new(/^a-z+:\\s+\w+/)
  end

  def test_compile
    Regexp.compile('dog')
    Regexp.compile('dog', option = Regexp::IGNORECASE)
    Regexp.compile('dog', code = 'n')
    Regexp.compile('dog', option = Regexp::IGNORECASE, code = 'n')
    Regexp.compile(/^a-z+:\\s+\w+/)
  end

  def test_escape
    Regexp.escape('\*?{}.')
  end

  def test_try_convert
    Regexp.try_convert(/re/)    #=> /re/
    Regexp.try_convert("re")    #=> nil

    o = Object.new
    Regexp.try_convert(o)       #=> nil
    def o.to_regexp() /foo/ end
    Regexp.try_convert(o)       #=> /foo/
  end

  def test_quote
    Regexp.quote('\*?{}.')
  end

  def test_union
    Regexp.union                              #=> /(?!)/
    Regexp.union("penzance")                  #=> /penzance/
    Regexp.union("a+b*c")                     #=> /a\+b\*c/
    Regexp.union("skiing", "sledding")        #=> /skiing|sledding/
    Regexp.union("skiing", "sledding", "sky") #=> /skiing|sledding/
    Regexp.union(["skiing", "sledding"])      #=> /skiing|sledding/
    Regexp.union(/dogs/, /cats/i)             #=> /(?-mix:dogs)|(?i-mx:cats)/
    Regexp.union("dogs", /cats/i)             #=> /dogs|(?i-mx:cats)/
    Regexp.union(["dogs", /cats/i])           #=> /dogs|(?i-mx:cats)/
  end

  # test_==
  def test_double_equal
    /abc/  == /abc/x #=> false
    /abc/  == /abc/i #=> false
    /abc/  == /abc/u #=> false
    /abc/u == /abc/n #=> false
  end

  # test_===
  def test_triple_equal
    a = "HELLO"
    if (/\A[a-z]*\z/ === a)
      "Lower case\n"
    elsif (/\A[A-Z]*\z/ === a)
      "Upper case\n"
    else
      "Mixed case\n"
    end
    #=> "Upper case"
  end

  # test_=~
  def test_equal_tilde
    /at/ =~ "input data" #=> 7
    /ax/ =~ "input data" #=> nil
  end

  def test_casefold?
    /a/.casefold?      #=> false
    /a/i.casefold?     #=> true
    /(?i:a)/.casefold? #=> false
  end

  def test_encoding
    /(?i:a)/.encoding
  end

  def test_fixed_encoding?
    /a/.fixed_encoding?  #=> false
    /a/u.fixed_encoding? #=> true
  end

  def test_hash
    /a/.hash
  end

  def test_inspect
    /ab+c/ix.inspect #=> "/ab+c/ix"
  end

  def test_match
    /R.../.match("Ruby")    #=> MatchData
    /P.../.match("Ruby")    #=> nil
    /R.../.match(:Ruby)     #=> MatchData
    /R.../.match(nil)       #=> nil
    o = Class.new { def to_str; "object"; end }.new
    /R.../.match(o)         #=> nil
    /R.../.match("Ruby", 1) #=> nil
    /M(.*)/.match("Matz") do |m|
      # nop
    end
    /M(.*)/.match("Matz", 1) do |m|
      # nop
    end
  end

  def test_match?
    /R.../.match?("Ruby")    #=> true
    /P.../.match?("Ruby")    #=> false
    /R.../.match?(:Ruby)     #=> true
    /R.../.match?(nil)       #=> false
    o = Class.new { def to_str; "object"; end }.new
    /R.../.match?(o)         #=> false
    /R.../.match?("Ruby", 1) #=> false
  end

  def test_named_captures
    /(?<foo>.)(?<bar>.)/.named_captures #=> {"foo"=>[1], "bar"=>[2]}
    /(?<foo>.)(?<foo>.)/.named_captures #=> {"foo"=>[1, 2]}
    /(.)(.)/.named_captures             #=> {}
  end

  def test_names
    /(?<foo>.)(?<bar>.)(?<baz>.)/.names #=> ["foo", "bar", "baz"]
    /(?<foo>.)(?<foo>.)/.names          #=> ["foo"]
    /(.)(.)/.names                      #=> []
  end

  def test_options
    /cat/.options                   #=> 0
    /cat/ix.options                 #=> 3
    Regexp.new('cat', true).options #=> 1
    /\xa1\xa2/e.options             #=> 16
  end

  def test_source
    /ab+c/ix.source #=> "ab+c"
    /\x20\+/.source #=> "\\x20\\+"
  end

  def test_to_s
    /ab+c/ix.to_s #=> "(?ix-m:ab+c)"
  end

  def test_eql?
    /abc/.eql?(/abc/x)  #=> false
    /abc/.eql?(/abc/i)  #=> false
    /abc/.eql?(/abc/u)  #=> false
    /abc/u.eql?(/abc/n) #=> false
  end
end
