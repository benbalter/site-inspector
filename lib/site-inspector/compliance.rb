class SiteInspector

  def path_exists?(path)
    url = URI.join uri, path
    Typhoeus::Request.get(url, followlocation: true, timeout: 10).success?
  end

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
