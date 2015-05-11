class SiteInspector
  class RailsCache
    def get(request)
      Rails.cache.read(request)
    end

    def set(request, response)
      Rails.cache.write(request, response)
    end
  end
end
