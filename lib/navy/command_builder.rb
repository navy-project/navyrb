module Navy
  class CommandBuilder

    attr_reader :container, :spec

    def initialize(container)
      @container = container
      @spec = container.specification
    end

    def build(options = {})
      cmd = []
      docker_run(cmd)
      docker_name(cmd)
      docker_links(cmd)
      docker_env(cmd)
      docker_volumes_from(cmd)
      docker_misc_args(cmd)

      docker_image(cmd)
      execute_command(cmd, options)
      cmd.compact
    end

    private

    def docker_run(cmd)
      if container.daemon?
        cmd << "docker run -d"
      else
        cmd << "docker run --rm"
      end
    end

    def docker_image(cmd)
      cmd << spec[:image]
    end

    def docker_name(cmd)
      cmd << "--name #{spec[:container_name]}"
    end

    def docker_links(cmd)
      links = spec[:links] || []
      links.each do |link|
        from, to = link
        cmd << "--link=#{from}:#{to}"
      end
    end

    def docker_env(cmd)
      envvars = spec[:env] || {}
      envvars.each do |key, value|
        cmd << "-e=\"#{key}=#{value}\""
      end
    end

    def docker_volumes_from(cmd)
      vols = spec[:volumes_from] || []
      vols.each do |vol|
        cmd << "--volumes-from=#{vol}"
      end
    end

    def docker_misc_args(cmd)
      cmd << spec[:docker_args]
    end

    def execute_command(cmd, options)
      cmd << (options[:command] || spec[:cmd])
    end
  end
end
