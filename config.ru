#!/usr/bin/env ruby
# Id$ nonnax 2022-04-02 21:55:16 +0800
require_relative 'lib/almost'
require 'json'

use Rack::Static, :urls => ["/css"], :root=>'public'

settings[:render][:layout]='view/layout.erb'
settings[:render][:views]='view'

get( '/login' ) { |param|
  # save once
  session[:name] ||= param[:name] || 'nald'
  'Welcome, '+String(session[:name])
}

get( '/' ) { |param|
  unless session[:name] 
    res.redirect '/login'
  else
    'Hello, '+String(session[:name])
  end
}

get( '/:hey' ) { |hey, params|
  session[:name]
  res.json %i{hey params session}.zip([hey, params, session.inspect]).to_h.to_json
}

get( '/:room/:id' ) { |room, id, params|
  session[:name]
  res.erb :'owner/room', name: session[:name], room:, id:, params:, markdown: true
}

post( '/hey' ) {'Post Hey'}

handle('404'){ 'Not here'}

puts JSON.pretty_generate(Almost.handler)

run Almost.new

