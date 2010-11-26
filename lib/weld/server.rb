require 'sinatra/base'

class Weld::Server < Sinatra::Base

  get %r{^/([^/]+)\.(css|js)$} do |name, type|
    @weld ||= Weld.new(settings.config_file)

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
    rescue Weld::FileNotFoundError => e
      raise Sinatra::NotFound
    end
  end

end
