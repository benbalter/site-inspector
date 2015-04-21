class SiteInspector
  class DiskCache
    def initialize(dir = nil, replace = nil)
      @dir     = dir || ENV['CACHE']
      @replace = replace || ENV['CACHE_REPLACE']
      @memory  = {}
    end

    def path(request)
      File.join(@dir, request.cache_key)
    end

    def get(request)
      return unless File.exist?(path(request))
      return @memory[request] if @memory[request]

      if @replace
        FileUtils.rm(path(request))
        nil
      else
        begin
          contents = File.read(path(request))
          Marshal.load(contents)
        rescue ArgumentError
          FileUtils.rm(path(request))
          nil
        end
      end
    end

    def set(request, response)
      File.write(path(request), Marshal.dump(response))
      @memory[request] = response
    end
  end
end
