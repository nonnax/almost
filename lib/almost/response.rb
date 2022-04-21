#!/usr/bin/env ruby
# frozen_string_literal: true

# Id$ nonnax 2022-04-21 16:29:54 +0800
require 'kramdown'

class Almost
  K = Kramdown::Document
  # session error fix
  class Response < Rack::Response
    def json(s)
      headers[Rack::CONTENT_TYPE] = 'application/json'
      s
    end

    def html(s)
      headers[Rack::CONTENT_TYPE] = 'text/html; charset=utf-8'
      s
    end

    def erb(s, **locals)
      s = file(s) if s.is_a?(Symbol)
      l = self.class.settings[:render][:layout]
      layout_f = File.read(l) # if File.exist?(l)
      layout_f ||= '<%=yield%>'
      s = _erb(layout_f, **locals) do
        _erb(s, binding, **locals).then do |s|
          (locals.keys & %i[md markdown]).any? ? K.new(s).to_html : s
        end
      end
      html s
    end

    def _erb(s, b = binding, **locals)
      b.dup.tap { |b| b.instance_eval { locals.each { |k, v| local_variable_set(k, v) } } }
       .then { |b| ERB.new(s).result(b) }
    end

    def file(f)
      File.read File.join(self.class.settings[:render][:views], "#{f}.erb")
    end
  end
end
