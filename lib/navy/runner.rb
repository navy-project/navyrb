require 'open3'


class Navy::Runner
  def self.launch(cmd, options={})
    logger = options[:logger] || Navy::Logger.new

    command = cmd.join(' ')
    logger.notice("Launching #{command}")
    stdout, stderr, status = Open3.capture3(cmd.join(' '))
    unless status.success?
      logger.color(:red, "Error")
      logger.color(:red, stderr)
    end
    status.success?
  end
end
