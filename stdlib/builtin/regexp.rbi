class Regexp
  def self.compile: (String) -> Regexp
                  | (String, Integer) -> Regexp
                  | (String, bool) -> Regexp
                  | (Regexp) -> Regexp
  def self.escape: (String) -> String
  def self.last_match: -> MatchData?
                     | (Integer) -> String?
  def self.quote: (String) -> String
  def self.try_convert: (any) -> Regexp?
  def self.union: (*String) -> Regexp
                | (Array[String]) -> Regexp
                | (*Regexp) -> Regexp
                | (Array[Regexp]) -> Regexp

  def initialize: (String) -> any
                | (String, Integer) -> any
                | (String, bool) -> any
                | (Regexp) -> any

  def `===`: (String) -> bool
  def `=~`: (String) -> Integer?
  def casefold?: -> bool
  def encoding: -> Encoding
  def fixed_encoding?: -> bool
  def match: (String) -> MatchData?
           | (String, Integer) -> MatchData?
           | [X] (String) { (MatchData) -> X } -> X?
           | [X] (String, Integer) { (MatchData) -> X } -> X?
  def match?: (String) -> bool
            | (String, Integer) -> bool
  def named_captures: -> Hash[String, Array[Integer]]
  def names: -> Array[String]
  def options: -> Integer
  def source: -> String
  def `~`: -> Integer?
end
