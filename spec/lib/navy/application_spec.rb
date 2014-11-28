require 'spec_helper'

describe Navy::Application do
  let(:config) do
    cfg = Navy::Configuration.from_string <<-YAML
    apps:
      app1:
        image: given_image
        links:
          - dep1
          - otherapp1
          - dep3
        modes:
          mode1: command1 to run
          mode2: command2 to run
        proxy_to:
          mode1: 1234
        env_var: SOME_ENV
        volumes_from:
          - somevol
          - othervol
      otherapp1:
        image: foo
      otherapp2:
        image: bar
    environments:
      env:
        dependencies:
          dep1:
            proxy_to: 9999
          dep2:
          dep3:
        pre:
          - pretask1
          - pretask2
        post:
        docker:
          app1: --some argument
    YAML
    cfg.set_env('env')
    cfg
  end

  subject { config.find_app 'app1' }

  it "has given image" do
    expect(subject.image).to eq "given_image"
  end

  it "has given modes" do
    modes = subject.modes
    expect(modes['mode1']).to eq "command1 to run"
    expect(modes['mode2']).to eq "command2 to run"
  end

  it "has given volumes" do
    vols = subject.volumes_from
    expect(vols).to eq ['somevol', 'othervol']
  end

  describe "Dependencies" do
    it "returns names of dependencies for the app" do
      deps = subject.dependencies(config)
      expect(deps).to eq ['dep1', 'dep3']
    end
  end

  describe "Linked Apps" do
    it "returns names of other applications the app should link to" do
      deps = subject.linked_apps(config)
      expect(deps).to eq ['otherapp1']
    end
  end

  describe "Proxy settings" do
    context "with modes" do
     it "can have a proxy and a port" do
        expect(subject.proxy_to?('mode1')).to be true
        expect(subject.proxy_to?('mode2')).to be false

        expect(subject.proxy_port('mode1')).to eq 1234
     end
    end

    context "without modes" do
      it "has the port" do
        app = config.dependencies.detect {|d| d.name == 'dep1' }
        expect(app.proxy_to?).to be
        expect(app.proxy_port).to eq 9999
      end
    end
  end

  describe "Env Variable" do
    it "returns named env var" do
      expect(subject.env_var?).to be true
      expect(subject.env_var).to eq 'SOME_ENV'

      app = config.find_app('otherapp1')
      expect(app.env_var?).to be false
    end
  end

end
