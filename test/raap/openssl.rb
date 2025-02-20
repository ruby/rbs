require 'raap'

RaaP::Type.register('OpenSSL::BN') do
  sized do |size|
    [:call, OpenSSL::BN, :new, [integer.pick(size: size)], {}, nil]
  end
end

argv = [
  '--require', 'openssl',
  '--library', 'openssl',
  '--size-by', '2',
  '--log-level', 'info',
]

%w[
  +
  -
  *
  /
  %
  **
  cmp
  copy
  gcd
  mod_add
  mod_exp
  mod_mul
  mod_sqr
  mod_sub
  ucmp
].each do |instance_method|
  argv << "OpenSSL::BN##{instance_method}"
end

RaaP::CLI.new(argv).load.run
