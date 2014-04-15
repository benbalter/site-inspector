require 'sinatra'
require 'rack/coffee'
require 'site-inspector'
require 'rack-cache'

GLOBAL_CACHE_TIMEOUT = 30

module SiteInspectorServer
  class App < Sinatra::Base

    use Rack::Coffee, root: 'public', urls: '/assets/javascripts'

    use Rack::Cache,
        :verbose => true,
        :metastore => "file:cache/meta",
        :entitystore => "file:cache/body"

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

    get "/domains/:domain.json" do
      content_type :json
      site = SiteInspector.new params[:domain]
      site.to_json
    end

    get "/domains/:domain" do
      cache_control :public, max_age: GLOBAL_CACHE_TIMEOUT
      site = SiteInspector.new params[:domain]
      render_template :domain, site: site
    end

  end
end
