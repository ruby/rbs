# @type var int: Integer
# @type var float: Float

float = rand(0)
int = rand(1)

i = 2
int = rand(i)

int = rand(1..10) || 0
float = rand((1.0)..(2.2)) || 0.1

int = rand(1.1)
