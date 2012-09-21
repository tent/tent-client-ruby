# Tent Ruby Client [![Build Status](https://secure.travis-ci.org/tent/tent-client-ruby.png)](http://travis-ci.org/tent/tent-client-ruby)

TentClient implements a [Tent Protocol](http://tent.io) client library in Ruby.
It is incomplete, currently only the endpoints required by
[tentd](https://github.com/tent/tentd) and
[tentd-admin](https://github.com/tent/tentd-admin) have been implemented.

## Usage

```ruby
# Tent profile discovery
TentClient.new.discover("http://tent-user.example.org")

# Server communication
client = TentClient.new('http://tent-user.example.org',
                        :mac_key_id => 'be94a6bf',
                        :mac_key => '974af035',
                        :mac_algorithm => 'hmac-sha-256')
client.following.create('http://another-tent.example.com')
```

## Contributions

If you find missing endpoints/actions, please submit a pull request.
