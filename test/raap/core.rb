require 'raap'

argv = [
  '--size-by', '2',
  '--allow-private'
]

argv << 'Set[Integer]'
argv << 'Enumerable[Integer]#to_set'

RaaP::CLI.new(argv).load.run
