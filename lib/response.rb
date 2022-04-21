#!/usr/bin/env ruby
# Id$ nonnax 2022-04-21 16:29:54 +0800
require 'kramdown'
class Almost
  K = Kramdown::Document
  class Response < Rack::Response # session error fix
    def json(j)
      instance_eval do
        headers[Rack::CONTENT_TYPE]='application/json'
        j
      end
    end
    def html(s)
      instance_eval do
        headers[Rack::CONTENT_TYPE]='text/html; charset=utf-8'
        s
      end
    end

    def erb(s, **locals)
      s = file(s) if s.is_a?(Symbol)
      l=Almost.settings[:render][:layout]
      layout_f = File.read(l) #if File.exist?(l)
      layout_f ||= '<%=yield%>'
      s=_erb(layout_f, **locals) do
          _erb(s, binding, **locals).then{|s| 
            (locals.keys & [:md, :markdown]).any? ? K.new(s).to_html : s 
          }
      end
      self.html s 
    end
    def _erb s, b=binding, **locals
      b.dup
      .tap{ |b| b.instance_eval{ locals.each{|k, v|local_variable_set(k, v)}}}
      .then{|b| ERB.new(s).result(b)}
    end
  end 
end
