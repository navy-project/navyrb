module Navy::ContainerBuilding
  private

  def build_container
    Navy::Container.new :dependencies => @dependencies,
                              :specification => @specification
  end

  def build_app_dependencies(app, config)
    links = app.dependencies(config)
    flags = {:convoy => options[:convoy]}
    links.each do |link|
      name = config.container_name(link, flags)
      dependencies << name
    end
  end

  def build_app_links(app, config)
    links = app.linked_apps(config)
    links.each do |link|
      fqdn = app_fqdn(link, config)
      env = app_env_addr(link)
      specification[:env][env] = "https://#{fqdn}"
      specification[:links] << ['host_proxy', fqdn]
    end
  end
   

  def build_dep_links(app, config)
    links = app.dependencies(config)
    flags = {:convoy => options[:convoy]}
    links.each do |link|
      name = config.container_name(link, flags)
      specification[:links] << [name, link]
    end
  end

  def app_fqdn(app, config)
    parts = []
    parts << @convoy_id
    parts << app
    parts << @cluster
    parts.compact.join('-')
  end

  def app_env_addr(app)
    "#{app.upcase}_HOST_ADDR"
  end
  
  def build_env_flags(app, config)
    if app.env_var?
      specification[:env][app.env_var] = config.environment
    end
  end
  
  def build_volumes_flags(app, config)
    app.volumes_from.each do |v|
      specification[:volumes_from] << v
    end
  end

  def build_additional_args(app, config)
    specification[:docker_args] = config.docker_args(app.name)
  end


end
