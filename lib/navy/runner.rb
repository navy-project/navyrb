require 'open3'


class Navy::Runner
  def self.launch(cmd, options={})
    logger = options[:logger] || Navy::Logger.new(:channel => "navyrb")

    command = cmd.join(' ')
    logger.info("Launching #{command}")
    stdout, stderr, status = Open3.capture3(cmd.join(' '))

    unless status.success?
      stderr.lines do |line|
        logger.error(line)
      end
    end
    status.success?
  end
end
