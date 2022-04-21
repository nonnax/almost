# almost sinatra
```ruby
require 'almost'

get( '/:room/:id' ) { |room, id, params|
  session[:name]='almost'
  erb [room, id, params, '{user:[<%=name%>]}'].join(' '), name: session[:name]
}

handle('404'){ 'Not here'}

run Almost.new
```
