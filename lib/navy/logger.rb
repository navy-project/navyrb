class Navy::Logger
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

  attr_reader :prefix

  def color(color, message)
    "\033[0;#{COLOURS[color]}m#{message}\033[0;00m"
  end

  def notice(message)
    log color(:cyan,message)
  end

  def info(message)
    log color(:yellow, message)
  end

  def error(message)
    log color(:red, message)
  end

  def debug(message)
    log message
  end

  def threaded!
    thread = Thread.current.object_id
    colorid = (thread/7) % COLOURS.count
    colorkey = COLOURS.keys[colorid]
    @prefix = color(colorkey, "(#{thread}):")
  end

  private

  def log(message)
    puts [prefix, message].join(' ')
  end
end
