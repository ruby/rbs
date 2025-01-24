# Passing keyword args is allowed.
Net::HTTP.start('example.com', open_timeout: 10)

# Passing a hash object is also allowed, but it needs the predecessor arguments.
Net::HTTP.start('example.com', 443, nil, nil, nil, nil, { open_timeout: 10, read_timeout: 10 })
