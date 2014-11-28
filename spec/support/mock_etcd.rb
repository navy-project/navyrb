require 'json'

class MockEtcd
  def keys
    @keys ||= {}
  end

  def get(key)
    keys[key]
  end

  def set(key, value)
    keys[key] = value
  end

  def setJSON(key, value)
    keys[key] = value.to_json
  end

  def getJSON(key)
    value = keys[key]
    JSON.parse(value) if value
  end
end
