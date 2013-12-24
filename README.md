# Tent Ruby Client [![Build Status](https://travis-ci.org/tent/tent-client-ruby.png?branch=master)](https://travis-ci.org/tent/tent-client-ruby)

TentClient implements a [Tent Protocol](https://tent.io) client library in Ruby.

For authenticating your app, see [Omniauth-Tent](https://github.com/tent/omniauth-tent).

You should be familiar with [Faraday](https://github.com/lostisland/faraday) before continuing.

## Install

Add the following to your Gemfile

```ruby
gem "tent-client""
```

or

```
$ gem install tent-client
```

## Usage

**Setup**

```ruby
require "tent-client"
client = TentClient.new("https://entity.example.com")

# or, for more advanced use cases you may pass any of the following options:
options = {
  :server_meta => {}, #  deserialized JSON of the meta post (optional)
  :faraday_adapter => Faraday.default_adapter, # see https://github.com/lostisland/faraday for details (optional)
  :faraday_setup => proc { |f| }, # proc to be called for additional Faraday setup (optional)
  :ts_skew => 0 # see https://tent.io/docs/authentication#timestamp-skew for details (optional)
}
client = TentClient.new("https://entity.example.com", options)
```

**API Endpoints**

Object | Description
------ | -----------
`client.post` | An instance of `TentClient::Post`.
`client.post.head` | An instance of `TentClient:Post` where `GET`s are transformed into `HEAD`s.
`client.post.get(entity, post_id, params = {}, &block)` | `GET` `post`. Returns an instance of `Faraday::Response`.
`client.post.get_attachment(entity, post_id, attachment_name, params = {}, &block)` | `GET` `post_attachment` (redirect followed).
`client.post.mentions(entity, post_id, params = {}, &block)` | `GET` `post` with the `ACCEPT` header set accordingly.
`client.post.versions(entity, post_id, params = {}, &block)` | `GET` `post` with the `ACCEPT` header set accordingly.
`client.post.children(entity, post_id, params = {}, &block)` | `GET` `post` with the `ACCEPT` header set accordingly.
`client.post.create(data, params = {}, options = {}, &block)` | `POST` `post` where `data` is the deserialized JSON of the post. Attachments may be passed via the options object using the `:attachments` key and an array of objects with `:content_type`, `:category`, `:name`, and `:data` (may be a string or an object with a `read` method).
`client.post.delete(entity, post_id, params = {}, &block)` | `DELETE` `post`.
`client.post.list(params = {}, &block)` | `GET` `posts_feed`.
`client.attachment` | An instance of `TentClient::Attachment`.
`client.attachment.get(entity, digest, params = {}, &block)` | `GET` `attachment`.
`client.oauth_redirect_uri(params = {})` | Returns an instance of `URI`.
`client.oauth_token_exchange(data, &block)` | `POST` `oauth_token`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
