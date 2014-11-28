class Navy::Container
  attr_reader :specification, :dependencies, :options

  def initialize(options = {})
    @specification = options[:specification] || {}
    @dependencies = options[:dependencies] || []
    @logger = options[:logger] || Navy::Logger.new
  end

  def daemon?
    specification[:type] == "application"
  end

  def name
    specification[:container_name]
  end

  def app
    specification[:name]
  end

  def can_be_started?(etcd)
    dependencies.each do |dep|
      return false unless desired?(etcd, dep)
    end
    true
  end

  def can_never_be_started?(etcd)
    dependencies.each do |dep|
      return true if errored?(etcd, dep)
    end
    false
  end

  def start
    if daemon?
      cmd = command_builder.build
      Navy::Runner.launch(cmd)
    else
      commands.each do |command|
        cmd = command_builder.build :command => command
        success = Navy::Runner.launch(cmd, :logger => @logger)
        return false unless success
      end
      true
    end
  end

  def stop
    cmd = ["docker rm -f", name]
    Navy::Runner.launch(cmd)
  end

  private

  def commands
    specification[:cmds] || []
  end

  def command_builder
    @command_builder ||= Navy::CommandBuilder.new(self)
  end

  def errored?(etcd, container_name)
    actual  = etcd.getJSON("/navy/containers/#{container_name}/actual")
    actual["state"] == "error" if actual
  end

  def desired?(etcd, container_name)
    desired = etcd.getJSON("/navy/containers/#{container_name}/desired")
    actual  = etcd.getJSON("/navy/containers/#{container_name}/actual")
    desired == actual
  end
end
