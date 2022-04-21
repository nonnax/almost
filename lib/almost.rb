#!/usr/bin/env ruby
# frozen_string_literal: true

# Id$ nonnax 2022-04-02 21:53:22 +0800
%w[rack securerandom].map{|l| require l}


class Almost
  PATTERN=Hash.new{|h, path| 
    h[path]=path
    .gsub(/:\w+/){ |match| '([^/?#]+)' }
    .then{|p| /^(#{p})\/?$/ } 
  }
  H=Hash.new{|h,k| h[k]=k.transform_keys(&:to_sym)}

  class Response < Rack::Response; end # fix session errors
  attr_reader :handler, :res, :req, :env
  class<<self
    alias _new new  
    def new
      app do 
        use Rack::Session::Cookie, secret: SecureRandom.hex(64)        
        run Almost._new
      end
    end
    def app(&block)
      @app ||= Rack::Builder.new(&block)
    end
    def use(m, *a, **h, &block)
      app.use m, *a, **h, &block
    end
  end
  
  def initialize
    @handler = Mapper.handler
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
    @req, @res, @env, md = Rack::Request.new(env), Almost::Response.new, env
    path, block = handler.detect{|k, p| md = k.match(req.path_info) }
    
    default do
      if block
        path, *vars = md&.captures
        body = instance_exec(*vars, H[req.params], &block[req.request_method]) # rescue nil
        res.write body
      end
    end
  rescue StandardError => e
    # pp e
    [500, {}, [e.message]]
  end

  def session
    env['rack.session'] || raise('Missing middleware, add: use Rack::Session::Cookie')
  end
  module Mapper
    D = Object.method(:define_method)
    # D[:new] { Rack::Builder.new{ run Almost.new }}
    D[:handler] { @handler ||= Hash.new { |h, k| h[k] = {} } }
    %w[get post put delete].map do |m| 
      D[m]{ |u, &b| Mapper.handler[PATTERN[u]][m.upcase] = b } 
    end
  end
  
end


Kernel.include Almost::Mapper
