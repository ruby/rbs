# These are valid because step is a number.

(1...3).step(1) { }
("A".."C").step(1) { }

# This works because "A" + "" is valid.
("A".."C").step("") { }

# This doesn't work but the type checker cannot detect it.
("A".."C").step(Exception.new) { }
