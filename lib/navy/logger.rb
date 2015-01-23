class Navy::Logger
  LEVELS = [:off, :fatal, :error, :warning, :info, :debug, :trace]

  COLOURS = {
    :black          => 30,
    :red            => 31,
    :green          => 32,
    :yellow         => 33,
    :blue           => 34,
    :magenta        => 35,
    :cyan           => 36,
    :bright_black   => 30,
    :bright_red     => 31,
    :bright_green   => 32,
    :bright_yellow  => 33,
    :bright_blue    => 34,
    :bright_magenta => 35,
    :bright_cyan    => 36
  }

  attr_reader :prefix, :level, :backend, :channel

  def self.environment_log_level
    return unless ENV["LOG_LEVEL"]

    ENV["LOG_LEVEL"].to_sym
  end

  def initialize(options = {})
    if options[:level] && !LEVELS.include?(options[:level])
      raise ArgumentError, "Your log level needs to be one of the following: #{LEVELS}"
    end
    @level = options[:level] || self.class.environment_log_level || :debug
    @backend = options[:backend] || $stdout
    @channel = options[:channel]
  end

  def color(color, message)
    "\033[0;#{COLOURS[color]}m#{message}\033[0;00m"
  end

  def fatal(message)
    log message, :fatal
  end

  def error(message)
    log message, :error
  end

  def warn(message)
    log message, :warning
  end

  def info(message)
    log message, :info
  end

  def debug(message)
    log message, :debug
  end

  def trace(message)
    log message, :trace
  end

  def threaded!
    thread = Thread.current.object_id
    colorid = (thread/7) % COLOURS.count
    colorkey = COLOURS.keys[colorid]
    @prefix = color(colorkey, "(#{thread}):")
  end

  private

  def should_log?(type)
    LEVELS.index(level) >= LEVELS.index(type)
  end

  def log(message, type)
    return unless should_log?(type)

    level_prefix = "[#{type.to_s.upcase[0,4]}]"

    result = [level_prefix]
    result << prefix unless prefix.nil?
    result << "- #{channel} -" unless channel.nil?
    result << message

    @backend.puts result.join(' ')
  end
end
