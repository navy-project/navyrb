require "navy/version"

module Navy
  autoload :Etcd, 'navy/etcd'
  autoload :Logger, 'navy/logger'
  autoload :Configuration, 'navy/configuration'
  autoload :Application, 'navy/application'
  autoload :CommandBuilder, 'navy/command_builder'
  autoload :Router, 'navy/router'
  autoload :Runner, 'navy/runner'
  autoload :Container, 'navy/container'
  autoload :ContainerBuilding, 'navy/container_building'
  autoload :AppContainerBuilder, 'navy/app_container_builder'
  autoload :TaskContainerBuilder, 'navy/task_container_builder'
end
