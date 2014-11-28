require 'spec_helper'

describe Navy::AppContainerBuilder do
  let(:app) do
    app = double(:name => 'the_app',
                 :image => 'the_image',
                 :linked_apps => [],
                 :dependencies => [],
                 :env_var? => false,
                 :proxy_to? => false,
                 :modes => {"themode" => "the mode command", "other" => "other command"},
                 :volumes_from => [])
    app
  end

  let(:config) do
    config = double :environment => "config_env",
                    :docker_args => nil,
                    :pre_tasks => [],
                    :post_tasks => []
    allow(config).to receive(:container_name) do |name, options|
      convoy = options[:convoy]
      mode = options[:mode]
      scale = options[:scale]
      name = [convoy, name, mode, scale].compact.join '_'
      "container_for_#{name}"
    end
    config
  end

  let(:options) { {:convoy => 'convoy_id', :cluster => 'the-cluster.com', :mode => 'themode', :scale => 3} }

  subject do
    described_class.new(app, config, options).build
  end

  describe "#dependencies" do
    context 'with dependencies' do
      before :each do
        allow(app).to receive(:dependencies).with(config).and_return(['dep1', 'dep2'])
      end

      it "returns array of container names depended on" do
        expect(subject.dependencies).to eq ['container_for_convoy_id_dep1', 'container_for_convoy_id_dep2']
      end
    end
    
    context 'with pre tasks' do
      before :each do
        allow(config).to receive(:pre_tasks) { |app| ["pre1_#{app}", "pre2_#{app}"] }
      end

      it "includes the task containers" do
        expect(subject.dependencies).to eq ['container_for_convoy_id_the_app_pretasks']
      end
    end
  end

  describe "#specification" do
    let(:spec) { subject.specification }

    it "gives needed details to bring up the container" do
      expect(spec[:container_name]).to eq "container_for_convoy_id_the_app_themode_3"
      expect(spec[:name]).to eq "the_app"
      expect(spec[:image]).to eq "the_image"
      expect(spec[:type]).to eq "application"
      expect(spec[:mode]).to eq "themode"
      expect(spec[:cmd]).to eq "the mode command"
      #expect(spec[:sha]).to eq "todo"
    end

    describe "Application Links" do
      before :each do
        expect(app).to receive(:linked_apps).with(config).and_return(['app1', 'app2'])
      end

      it "sets an environment variable for the host" do
        env = spec[:env]

        expect(env['APP1_HOST_ADDR']).to eq "https://convoy_id-app1-the-cluster.com"
        expect(env['APP2_HOST_ADDR']).to eq "https://convoy_id-app2-the-cluster.com"
      end

      it "links to the host proxy" do
        links = spec[:links]
        expect(links).to include ['host_proxy', 'convoy_id-app1-the-cluster.com']
        expect(links).to include ['host_proxy', 'convoy_id-app2-the-cluster.com']
      end
    end

    describe "Dependency Links" do
      before :each do
        expect(app).to receive(:dependencies).with(config).and_return(['dep1', 'dep2'])
      end

      it "links to the container" do
        links = spec[:links]
        expect(links).to include ['container_for_convoy_id_dep1', 'dep1']
        expect(links).to include ['container_for_convoy_id_dep2', 'dep2']
      end
    end

    describe "Environment" do
      context "when there's an env_variable" do
        before :each do
          expect(app).to receive(:env_var?) { true }
          expect(app).to receive(:env_var) { "THE_ENV_VAR" }
        end

        it "sets an environment variable with the config's environment" do
          env = spec[:env]
          expect(env['THE_ENV_VAR']).to eq 'config_env'
        end
      end

      context "when there's no env variable" do
       it "sets no environment variable" do
          env = spec[:env]
          expect(env['THE_ENV_VAR']).to be_nil
        end
      end
    end

    describe "Proxy" do
      context "with a proxy setting" do
        before :each do 
          expect(app).to receive(:proxy_to?) { true }
          expect(app).to receive(:proxy_port) { 1234 }
        end

        it "adds a VIRTUAL_HOST variable for the application" do
          env = spec[:env]
          expect(env['VIRTUAL_HOST']).to eq 'convoy_id-the_app-the-cluster.com'
        end

        it "adds a VIRTUAL_PORT variable for the application" do
          env = spec[:env]
          expect(env['VIRTUAL_PORT']).to eq 1234
        end
      end

      context "with no proxy" do
        it "adds no proxy variables" do
          env = spec[:env]
          expect(env.keys.detect { |c| c.match /VIRTUAL/ }).to be_nil
        end
      end
    end

    describe "Volumes" do
      before :each do
        expect(app).to receive(:volumes_from).and_return(['fromvol1', 'fromvol2'])
      end

      it "adds any given volumes from" do
        vols = spec[:volumes_from]
        expect(vols).to eq ['fromvol1', 'fromvol2']
      end
    end

    describe "Docker Flags" do
      before :each do
        expect(config).to receive(:docker_args).and_return('-some flags for docker')
      end

      it "adds them to the specification" do
        expect(spec[:docker_args]).to eq "-some flags for docker"
      end
    end
  end
end
