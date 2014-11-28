class Navy::AppContainerBuilder
  include Navy::ContainerBuilding

  attr_reader :specification, :dependencies, :options

  def initialize(app, config, options)
    @options = options.dup
    @options[:app] = app
    @options[:config] = config
  end

  def build
    @specification = {
      :type => "application",
      :env => {},
      :links => [],
      :volumes_from => []
    }
    @dependencies = []
    app = options.delete :app
    config = options.delete :config
    @options = options
    build_specification(app, config)
    build_dependencies(app, config)
    build_container
  end

  private

  def build_dependencies(app, config)
    build_app_dependencies(app, config)
    build_task_dependencies(app, config)
  end


  def build_task_dependencies(app, config)
    tasks = config.pre_tasks(app.name)
    unless tasks.empty?
      flags = {:mode => :pretasks, :convoy => options[:convoy]}
      dependencies << config.container_name(app.name, flags)
    end
  end

  def build_specification(app, config)
    @convoy_id = options[:convoy]
    @cluster = options[:cluster]
    specification[:name] = app.name
    specification[:container_name] = config.container_name(app.name, options)
    specification[:image] = app.image
    mode = options[:mode]
    specification[:mode] = mode
    if app.modes
      specification[:cmd] = app.modes[mode]
    end
    build_app_links(app, config)
    build_dep_links(app, config)
    build_env_flags(app, config)
    build_proxy_flags(app, config)
    build_volumes_flags(app, config)
    build_additional_args(app, config)
  end

  def build_proxy_flags(app, config)
    mode = options[:mode]
    if app.proxy_to?(mode)
      fqdn = app_fqdn(app.name, config)
      port = app.proxy_port(mode)
      specification[:env]['VIRTUAL_HOST'] = fqdn
      specification[:env]['VIRTUAL_PORT'] = port
    end
  end
end
