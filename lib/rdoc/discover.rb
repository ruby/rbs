begin
    gem 'rdoc', '~> 6.4.0'
    require 'rdoc/parser/rbs'
rescue Gem::LoadError
    # Error :sad:
rescue Exception
    # Exception :sad:
end
