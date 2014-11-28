class Navy::TaskContainerBuilder
  include Navy::ContainerBuilding

  attr_reader :app, :config, :options, :dependencies, :specification, :convoy_id, :cluster

  def initialize(app, config, options)
    @app = app
    @config = config
    @options = options
    @convoy_id = options[:convoy]
    @cluster = options[:cluster]
    @specification = {
      :type => "task",
      :env => {},
      :links => [],
      :volumes_from => []
    }
    @dependencies = []
  end

  def build_pre
    tasks = config.pre_tasks(app.name)
    unless tasks.empty?
      build_task_container_settings(:pre, app, config, tasks)
      build_app_dependencies(app, config)
      build_dep_links(app, config)
      build_env_flags(app, config)
      build_volumes_flags(app, config)
      build_additional_args(app, config)
      build_container
    end
  end

  def build_post
    tasks = config.post_tasks(app.name)
    unless tasks.empty?
      build_task_container_settings(:post, app, config, tasks)
      build_mode_dependencies(app, config)
      build_app_links(app, config)
      build_dep_links(app, config)
      build_env_flags(app, config)
      build_volumes_flags(app, config)
      build_additional_args(app, config)
      build_container
    end
  end

  private

  def build_task_container_settings(type, app, config, cmds)
    flags = {:mode => "#{type}tasks", :convoy => @convoy_id}
    specification[:name] = app.name
    specification[:container_name] = config.container_name(app.name, flags)
    specification[:image] = app.image
    specification[:cmds] = cmds
  end

  def build_mode_dependencies(app, config)
    if app.modes
      app.modes.each do |mode, cmd|
        flags = {:mode => mode, :scale => 1, :convoy => @convoy_id}
        dependencies << config.container_name(app.name, flags)
      end
    else
      flags = {:scale => 1, :convoy => @convoy_id}
      dependencies << config.container_name(app.name, flags)
    end
  end

end
