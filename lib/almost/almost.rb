#!/usr/bin/env ruby
# frozen_string_literal: true

# Id$ nonnax 2022-04-02 21:53:22 +0800
%w[rack securerandom].map { |l| require l }
%w[response].map { |l| require_relative l }

D = Object.method(:define_method)
class Almost
  PATTERN = Hash.new do |h, path|
    h[path] =
      path.gsub(/:\w+/) { |_match| '([^/?#]+)' }.then { |p| %r{^(#{p})/?$} }
  end
  H = Hash.new { |h, k| h[k] = k.transform_keys(&:to_sym) }
  @settings = Hash.new { |h, k| h[k] = {} }
  @handler = Hash.new { |h, k| h[k] = {} }

  class << self
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
      app.use(m, *a, **h, &block)
    end

    attr_reader :handler, :settings
  end

  attr_reader :handler, :res, :req, :env

  def initialize
    @handler = self.class.handler
  end

  def call(env)
    @req, @res, @env, md = Rack::Request.new(env), Almost::Response.new, env
    _, block = handler.detect { |k, _| md = k.match(req.path_info) }

    default do
      if block
        _, *vars = md&.captures
        body = instance_exec(*vars, H[req.params], &block[req.request_method]) # rescue nil
        res.write body
      end
    end
  rescue StandardError => e
    [500, {}, [e.message]]
  end

  def session
    env['rack.session'] || raise('Missing middleware, add: use Rack::Session::Cookie')
  end

  def default
    res.status = 200
    unless yield
      res.status = 404
      not_found = handler[PATTERN[res.status.to_s]]['HANDLE']
      body = instance_eval(&not_found) if not_found.respond_to?(:call)
      body ||= 'Not Found'
      res.write body
    end
    res.finish
  end

  module Mapper
    D[:handler] {  Almost.handler  }
    D[:settings] { Almost.settings }
    %w[get post put delete handle].map do |m|
      D[m] { |u, &b| Almost.handler[PATTERN[u]][m.upcase] = b }
    end
  end

  # default settinss
  settings[:render][:layout] = 'views/layout.erb'
  settings[:render][:views] = 'views/'
  settings[:static][:css] = 'public/css'
end

Kernel.include Almost::Mapper
