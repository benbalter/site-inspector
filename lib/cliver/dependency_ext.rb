# frozen_string_literal: true

module Cliver
  class Dependency
    # Memoized shortcut for detect
    # Returns the path to the detected dependency
    # Raises an error if the dependency was not satisfied
    def path
      @path ||= detect!
    end

    # Returns the version of the resolved dependency
    def version
      return @version if defined? @version

      detected = installed_versions.find { |p, _v| p == path }
      @version = detected&.last
    end

    def major_version
      version&.split('.')&.first
    end
  end
end
