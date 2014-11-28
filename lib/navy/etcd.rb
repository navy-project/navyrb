require 'json'
require 'net/http'

module Navy
  class Etcd
    Response = Struct.new(:etcd_index, :action, :node, :prevNode) do
      def key
        node.key
      end
    end

    class Node
      attr_reader :createdIndex, :modifiedIndex, :value, :key

      def initialize(data)
        data ||= {}
        parse_data data, :createdIndex, :modifiedIndex,
                         :value, :key
      end

      private

      def parse_data(data, *attrs)
        attrs.each do |attr|
          instance_variable_set("@#{attr}", data[attr.to_s])
        end
      end

    end

    def self.client(options)
      new(options)
    end

    def initialize(options)
      @options = options
    end

    def get(key, params = {})
      response = make_get(key, params)
      json = JSON.parse(response.body)
      Response.new response['X-Etcd-Index'].to_i,
                   json['action'],
                   Node.new(json['node']),
                   Node.new(json['prevNode'])
    end

    def getJSON(key, params = {})
      record = get(key, params)
      json = record.node.value
      JSON.parse(json) if json
    end

    def watch(key, options = {})
      options[:wait] = true
      get(key, options)
    end

    def set(key, value)
      make_put(key, :value => value)
    end

    def setJSON(key, value)
      make_put(key, :value => value.to_json)
    end

    def queueJSON(key, value)
      make_post(key, :value => value.to_json)
    end

    def ls(dir)
      response = make_get(dir)
      dir = JSON.parse(response.body)["node"]
      dir["nodes"].map {|i| i["key"]}
    end

    def delete(key, params = {})
      response = make_delete(key, params)
      (200...299).include? response.code.to_i
    end

    private

    def make_uri(path)
      host = @options[:host]
      port = @options[:port] || 4001
      uri = URI("http://#{host}:#{port}")
      uri.path = "/v2/keys" + path
      uri
    end

    def make_http(uri)
      Net::HTTP.new(uri.host, uri.port)
    end

    def make_query(params)
      params.map do |k, v|
        "#{k}=#{v}"
      end.join '&'
    end

    def make_request(path, type, params = {})
      uri = make_uri(path)
      http = make_http(uri)
      if params.length > 0
        uri.query = make_query(params)
      end
      request = type.new(uri)
      yield request if block_given?
      http.request(request)
    end

    def make_delete(path, params = {})
      make_request(path, Net::HTTP::Delete, params)
    end

    def make_put(path, postdata = {})
      http, request = make_request(path, Net::HTTP::Put) do |request|
        request.set_form_data(postdata)
      end
    end

    def make_post(path, postdata = {})
      http, request = make_request(path, Net::HTTP::Post) do |request|
        request.set_form_data(postdata)
      end
    end

    def make_get(path, params = {})
      make_request(path, Net::HTTP::Get, params)
    end
  end
end
