require 'spec_helper'

describe Navy::Router do
  class ExampleHandler
    def self.handled
      @handled ||= {}
    end

    def handle_set(params, request)
      self.class.handled[:set] = params, request
    end

    def handle_delete(params, request)
      self.class.handled[:delete] = params, request
    end

  end

  let(:handler1) { Class.new(ExampleHandler) }
  let(:handler2) { Class.new(ExampleHandler) }

  subject do
    described_class.new do |r|
      r.route '^/a/route$', handler1
      r.route '^/a/:pattern/route$', handler2
    end
  end

  it "routes through to defined handlers" do
    request = double :key => '/a/route',
                     :action => :set

    subject.route(request)
    expect(handler1.handled[:set]).to eq [{}, request]
  end

  it "matches placeholder patters" do
    request = double :key => '/a/matching/route',
                     :action => :delete

    subject.route(request)
    expect(handler2.handled[:delete]).to eq [{'pattern' => 'matching'}, request]
  end

  it "gracefully handles unknown paths" do
    request = double :key => '/unkonwn/path',
                     :action => :delete
    expect { subject.route(request) }.to_not raise_error
  end

  it "gracefully handle unmapped action" do
    request = double :key => '/a/route',
                     :action => :unmapped
    expect { subject.route(request) }.to_not raise_error
  end

  it "passes down global options into the params" do
    options = {:foo => :bar}
    router = described_class.new(options) do |r|
      r.route 'example', handler1
    end

    request = double :key => 'example', :action => :set

    router.route(request)

    expect(handler1.handled[:set][0]).to eq({:foo => :bar})
  end
end
