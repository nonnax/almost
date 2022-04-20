#!/usr/bin/env ruby
# frozen_string_literal: true

# Id$ nonnax 2022-04-02 21:53:22 +0800
%w[rack securerandom].map{|l| require l}

PATTERN=Hash.new{|h, path| 
  h[path]=path
  .gsub(/:\w+/){ |match| '([^/?#]+)' }
  .then{|p| /^(#{p})\/?$/ } 
}

class App
  class Response < Rack::Response; end # fix session errors
  attr_reader :handler, :res, :req, :env

  def initialize
    @handler = Almost.handler
  end
  
  def default
    res.status = 200
    unless yield 
      res.status = 404
      res.write 'Not Found'
    end
    res.finish
  end
  
  def call(env)
    @req, @res, @env, md = Rack::Request.new(env), App::Response.new, env
    path, block = handler.detect{|k, p| md = k.match(req.path_info) }
    
    default do
      if block
        path, *vars = md&.captures
        body = instance_exec(*vars, &block[req.request_method]) # rescue nil
        res.write body
      end
    end
  rescue StandardError => e
    pp e
  end

  def session
    req.session
  end
end

module Almost
  D = Object.method(:define_method)
  D[:new] { App.new }
  D[:handler] { @handler ||= Hash.new { |h, k| h[k] = {} } }
  %w[get post put delete].map do |m| 
    D[m]{ |u, &b| Almost.handler[PATTERN[u]][m.upcase] = b } 
  end
end

Kernel.include Almost
