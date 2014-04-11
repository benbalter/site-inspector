require 'sinatra'
require 'rack/coffee'
require 'site-inspector'

module SiteInspectorServer
  class App < Sinatra::Base

    use Rack::Coffee, root: 'public', urls: '/assets/javascripts'

    use Rack::Session::Cookie, {
      :http_only => true,
      :secret => ENV['SESSION_SECRET'] || SecureRandom.hex
    }

    configure :production do
      require 'rack-ssl-enforcer'
      use Rack::SslEnforcer
    end

    def render_template(template, locals={})
      halt erb template, :layout => :layout, :locals => locals
    end

    get "/" do
      render_template :index
    end

    get "/domains/:domain" do
      site = SiteInspector.new params[:domain]
      render_template :domain, site: site
    end
  end
end
