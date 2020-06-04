require "json-schema"

class JSONValidator
  class Validator
    attr_reader :file

    def initialize(name)
      @file = Pathname(__dir__) + "../schema/#{name}.json"
    end

    def validate(object, fragment: nil)
      JSON::Validator.validate(
        file.to_s,
        object,
        { fragment: fragment }
      )
    end

    def validate!(object, fragment: nil)
      JSON::Validator.validate!(
        file.to_s,
        object,
        { fragment: fragment }
      )
    end
  end

  class <<self
    def location
      Validator.new("location")
    end

    def types
      Validator.new("types")
    end

    def comment
      Validator.new("comment")
    end

    def method_type
      Validator.new("methodType")
    end

    def members
      Validator.new("members")
    end

    def decls
      Validator.new("decls")
    end
  end
end
