require 'sinatra/base'

class Weld::Server < Sinatra::Base

  get %r{^/([^/\.]+)\.(css|js)$} do |name, type|
    begin
      @weld ||= Weld.new(settings.config_file)
    rescue => ex
      halt 500, ex.to_s
    end

    type      = type.to_sym
    no_minify = params.has_key?('no-minify') || params.has_key?('nominify')

    content_type(type == :css ? 'text/css' : 'application/javascript',
        :charset => 'utf-8')

    begin
      if no_minify
        @weld.component(name).merge(type)
      else
        @weld.component(name).compress(type)
      end

    rescue Weld::ComponentNotFoundError,
           Weld::FileNotFoundError => ex
      halt 404, ex.to_s

    rescue Weld::UnsupportedFileTypeError => ex
      halt 400, ex.to_s

    rescue => ex
      halt 500, ex.to_s
    end
  end

end
