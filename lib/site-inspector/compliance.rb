class SiteInspector
  class Domain
    def slash_data?
      @slash_data ||= path_exists?("/data")
    end

    def slash_developer?
      @slash_developer ||= (path_exists?("/developer") || path_exists?("/developers"))
    end

    def data_dot_json?
      @data_dot_json ||= path_exists?("/data.json")
    end
  end

  private

  # Given a path (e.g, "/data"), check if the given path exists on the canonical endpoint
  def path_exists?(path)
    uri = URI.join canonical_endpoint.uri, path
    canonical_endpoint.request(uri: uri, followlocation: true).success?
  end
end
