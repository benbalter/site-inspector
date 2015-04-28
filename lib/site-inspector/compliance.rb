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
end
