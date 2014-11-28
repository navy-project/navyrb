require 'yaml'

module Navy
  class Configuration
    attr_reader :definition, :environment

    def initialize(definition)
      @definition = definition
      @apps = parse_apps
    end

    def self.from_string(yaml_content)
      cfg = YAML.load(yaml_content)
      new(cfg)
    end

    def self.from_file(config_file)
      cfg = YAML.load_file(config_file)
      new(cfg)
    end

    def apps
      @apps.each do |app|
        yield app if block_given?
      end
    end

    def set_env(env)
      @environment = env
      @env = environments[environment] || {}
      @deps = parse_deps
      @pre = parse_pre_tasks
      @post = parse_post_tasks
      @docker_args = parse_docker_args
    end

    def container_name(app, options={})
      mode = options[:mode]
      convoy = options[:convoy]
      scale = options[:scale]
      [convoy, app, mode, scale].compact.join '_'
    end

    def applications
      @apps.map &:name
    end

    def find_app(name)
      @apps.detect {|a| a.name == name }
    end

    def dependencies
      @deps.each do |app|
        yield app if block_given?
      end
    end

    def pre_tasks(app)
      @pre[app] || []
    end

    def post_tasks(app)
      @post[app] || []
    end
    
    def docker_args(app)
      @docker_args[app]
    end

    private

    def environments
      definition['environments'] || {}
    end

    def parse_apps
      definition['apps'].map do |name, settings|
        Application.new(name, settings)
      end
    end

    def parse_deps
      deps = @env['dependencies'] || {}
      deps.map do |name, settings|
        Application.new(name, settings)
      end
    end

    def parse_pre_tasks
      @env['pre'] || {}
    end

    def parse_post_tasks
      @env['post'] || {}
    end

    def parse_docker_args
      @env['docker'] || {}
    end

  end
end
