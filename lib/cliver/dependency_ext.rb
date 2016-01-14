module Cliver
  class Dependency

    # Memoized shortcut for detect
    # Returns the path to the detected dependency
    # Raises an error if the dependency was not satisfied
    def path
      @detected_path ||= detect!
    end

    # Returns the version of the resolved dependency
    def version
      return @detected_version if defined? @detected_version
      version = installed_versions.find { |p, _v| p == path }
      @detected_version = version.nil? ? nil : version[1]
    end

    def major_version
      version.split('.').first if version
    end
  end
end
