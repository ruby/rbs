class RegexpTest < StdlibTest
  target Regexp
  using hook.refinement

  def test_new
    r1 = Regexp.new('^a-z+:\\s+\w+') #=> /^a-z+:\s+\w+/
    r2 = Regexp.new('cat', true)     #=> /cat/i
    r3 = Regexp.new(r2)              #=> /cat/i
    r4 = Regexp.new('dog', Regexp::EXTENDED | Regexp::IGNORECASE) #=> /dog/ix
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

  def test_compile
    r1 = Regexp.compile('^a-z+:\\s+\w+') #=> /^a-z+:\s+\w+/
    r2 = Regexp.compile('cat', true)     #=> /cat/i
    r3 = Regexp.compile(r2)              #=> /cat/i
    r4 = Regexp.compile('dog', Regexp::EXTENDED | Regexp::IGNORECASE) #=> /dog/ix
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
    /(.)(.)(.)/.match("abc") #=> MatchData
    /(.)(.)/.match("abc", 1) #=> MatchData
    /b/.match("a")           #=> nil
    /M(.*)/.match("Matz") do |m|
      # nop
    end
    /M(.*)/.match("Matz", 1) do |m|
      # nop
    end
  end

  def test_match?
    /R.../.match?("Ruby")    #=> true
    /R.../.match?("Ruby", 1) #=> false
    /P.../.match?("Ruby")    #=> false
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
