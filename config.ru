#!/usr/bin/env ruby
# Id$ nonnax 2022-04-02 21:55:16 +0800
require_relative 'lib/almost'
use Rack::Session::Cookie, secret: SecureRandom.hex(64)
use Rack::Static, :urls => ["/css"], :root=>'public'

get( '/' ) {
  session[:name]='nald'
  p session
  'Hello'
}
get( '/:hey' ) { |hey|
  pp session[:name]
  [hey, session.inspect].join(' ')
}
post( '/hey' ) {'Post Hey'}

# pp Almost.handler
run Almost.new
