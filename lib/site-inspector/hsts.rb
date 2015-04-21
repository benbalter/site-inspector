class SiteInspector
  # Utility parser for HSTS headers.
  # RFC: http://tools.ietf.org/html/rfc6797
  def self.hsts_parse(header)
    # no hsts for you
    nothing = {
      max_age: nil,
      include_subdomains: false,
      preload: false,
      enabled: false,
      preload_ready: false
    }

    return nothing unless header and header.is_a?(String)

    directives = header.split(/\s*;\s*/)

    pairs = []
    directives.each do |directive|
      name, value = directive.downcase.split("=")

      if value and value.start_with?("\"") and value.end_with?("\"")
        value = value.sub(/^\"/, '')
        value = value.sub(/\"$/, '')
      end

      pairs.push([name, value])
    end

    # reject invalid directives
    fatal = pairs.any? do |name, value|
      # TODO: more comprehensive rejection of characters
      invalid_chars = /[\s\'\"]/
      (name =~ invalid_chars) or (value =~ invalid_chars)
    end

    # good DAY, sir
    return nothing if fatal

    max_age_directive = pairs.find {|n, v| n == "max-age"}
    max_age = max_age_directive ? max_age_directive[1].to_i : nil
    include_subdomains = !!pairs.find {|n, v| n == "includesubdomains"}
    preload = !!pairs.find {|n, v| n == "preload"}

    enabled = !!(max_age and (max_age > 0))

    # Google's minimum max-age for automatic preloading
    eighteen_weeks = !!(max_age and (max_age >= 10886400))
    preload_ready = !!(eighteen_weeks and include_subdomains and preload)

    {
      max_age: max_age,
      include_subdomains: include_subdomains,
      preload: preload,
      enabled: enabled,
      preload_ready: preload_ready
    }
  end
end
