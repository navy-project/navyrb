module Navy
  class Application
    attr_reader :name

    def initialize(name, settings)
      @name = name
      @settings = settings
    end

    def image
      @settings['image']
    end

    def modes
      @settings['modes']
    end

    def volumes_from
      @settings['volumes_from'] || []
    end

    def links
      @settings['links'] || []
    end

    def dependencies(config)
      apps = config.applications
      links - apps
    end

    def linked_apps(config)
      apps = config.applications
      links = @settings['links'] || []
      links & apps
    end

    def env_var?
      !!@settings['env_var']
    end

    def env_var
      @settings['env_var']
    end

    def proxy_to?(mode=nil)
      if mode
        proxy = @settings['proxy_to'] || {}
        proxy.keys.include? mode
      else
        @settings['proxy_to']
      end
    end

    def proxy_port(mode=nil)
      if mode
        proxy = @settings['proxy_to'] || {}
        proxy[mode]
      else
        @settings['proxy_to']
      end
    end
  end
end
