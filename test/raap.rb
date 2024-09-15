# Specify the class/module and method names to be executed by RaaP.
# By prefixing with `!`, you can skip testing a method.

puts 'Set[Integer]'
puts 'Enumerable[Integer]#to_set'

%w[
  MD5
  SHA1
  RMD160
  SHA256
  SHA384
  SHA512
].each do |klass|
  %w[
    base64digest
    bubblebabble
    digest
    hexdigest
  ].each do |singleton_method|
    puts "Digest::#{klass}.#{singleton_method}"
  end

  %w[
    <<
    ==
    block_length
    digest_length
    reset
    update
    base64digest
    base64digest!
    block_length
    bubblebabble
    digest
    digest!
    digest_length
    hexdigest
    hexdigest!
    inspect
    length
    new
    reset
    size
    to_s
    update
    finish
    initialize_copy
  ].each do |instance_method|
    puts "Digest::#{klass}##{instance_method}"
  end
end
