# frozen_string_literal: true

class SiteInspector
  class DomainParser
    include NaughtyOrNice

    def self.parse(domain)
      new(domain).domain
    end
  end
end
