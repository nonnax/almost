# almost sinatra
```ruby
require 'almost'

get( '/:room/:id' ) { |room, id, params|
  session[:name]
  [room, id, params, session.inspect].join(' ')
}

run Almost.new
```
