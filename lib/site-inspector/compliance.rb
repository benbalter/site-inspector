class SiteInspector

  def path_exists?(path)
    url = uri(https?, !non_www?) + "/#{path}"
    Typhoeus::Request.get(url, followlocation: true).success?
  end

  def slash_data
    path_exists?("/data")
  end

  def slash_developer
    path_exists?("/developer")
  end

  def data_dot_json
    path_exists?("/data.json")
  end
end
