#!/usr/bin/env ruby
# Id$ nonnax 2022-04-02 21:55:16 +0800
require_relative 'lib/almost'
use Rack::Static, :urls => ["/css"], :root=>'public'

get( '/login' ) { |param|
  # save once
  session[:name] ||= param[:name] || 'nald'
}
get( '/' ) { |param|
  # save once
  unless session[:name] 
    res.redirect '/login'
  else
    'Hello, '+String(session[:name])
  end
}
get( '/:hey' ) { |hey, params|
  session[:name]
  [hey, params, session.inspect].join(' ')
}

get( '/:room/:id' ) { |room, id, params|
  session[:name]
  [room, id, params, session.inspect].join(' ')
}
post( '/hey' ) {'Post Hey'}

handle('404'){ 'Not here'}

pp Almost.handler

run Almost.new

