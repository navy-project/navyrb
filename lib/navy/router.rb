class Navy::Router
  class NullHandler; end

  class Routes
    def route(pattern, handlers)
      pattern = pattern.gsub(/:([a-z]+)/, '(?<\1>[a-z0-9\-_]+)')
      regex = Regexp.new(pattern)
      maps[regex] = handlers
    end

    def maps
      @maps ||= {}
    end

    def obtain(path)
      @maps.each do |pattern, handler|
        matches = pattern.match(path)
        if matches
          params = extract_params(matches)
          return handler.new, params
        end
      end
      return NullHandler.new, {}
    end

    private

    def extract_params(matches)
      params = {}
      matches.names.each do |name|
        params[name] = matches[name]
      end
      params
    end

  end

  def initialize(options = {})
    @routes = Routes.new
    @options = options
    yield @routes if block_given?
  end

  def route(request, options = {})
    opts = @options.merge(options)
    handler, params = @routes.obtain(request.key)
    params = opts.merge params
    dispatch(handler, params, request)
  end

  private

  def dispatch(handler, params, request)
    action = request.action
    message = handler_method(action)
    if handler.respond_to? message
      handler.public_send(message, params, request)
    end
  end

  def handler_method(action)
    "handle_#{action}"
  end
end
