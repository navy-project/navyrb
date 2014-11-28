require 'spec_helper'

describe Navy::TaskContainerBuilder do
  let(:app) do
    app = double(:name => 'the_app',
                 :image => 'the_image',
                 :linked_apps => [],
                 :dependencies => [],
                 :env_var? => false,
                 :proxy_to? => false,
                 :volumes_from => [],
                 :modes => nil)
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

  let(:options) { {:convoy => 'convoy_id', :cluster => 'the-cluster.com'} }

  describe "#build_pre" do
    subject { described_class.new(app, config, options).build_pre }

    context "when there are no pretasks" do
      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when there are pretasks" do
      before :each do
        allow(config).to receive(:pre_tasks) { |app| ["pre1_#{app}", "pre2_#{app}"] }
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
        
      end

      describe "#specification" do
        let(:spec) { subject.specification }

        it "gives needed details to bring up the container" do
          expect(spec[:container_name]).to eq "container_for_convoy_id_the_app_pretasks"
          expect(spec[:name]).to eq "the_app"
          expect(spec[:image]).to eq "the_image"
          expect(spec[:type]).to eq "task"
          expect(spec[:cmds]).to eq ["pre1_the_app", "pre2_the_app"]
          #expect(spec[:sha]).to eq "todo"
        end


        describe "Dependency Links" do
          before :each do
            allow(app).to receive(:dependencies).with(config).and_return(['dep1', 'dep2'])
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
  end

  describe "#build_post" do
    subject { described_class.new(app, config, options).build_post }

    context "when there are no post tasks" do
      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when there are post tasks" do
      before :each do
        allow(config).to receive(:post_tasks) { |app| ["post1_#{app}", "post2_#{app}"] }
      end

      describe "#dependencies" do
        it "includes the app container (at scale 1)" do
          expect(subject.dependencies).to eq ['container_for_convoy_id_the_app_1']
        end

        context 'when there are modes' do
          before :each do
            allow(app).to receive(:modes) { {:modea => 'cmd1', :modeb => 'cmd2'} }
          end

          it "includes each mode task container" do
            expect(subject.dependencies).to eq ['container_for_convoy_id_the_app_modea_1', 'container_for_convoy_id_the_app_modeb_1']
          end
        end
      end

      describe "#specification" do
        let(:spec) { subject.specification }

        it "gives needed details to bring up the container" do
          expect(spec[:container_name]).to eq "container_for_convoy_id_the_app_posttasks"
          expect(spec[:name]).to eq "the_app"
          expect(spec[:image]).to eq "the_image"
          expect(spec[:type]).to eq "task"
          expect(spec[:cmds]).to eq ["post1_the_app", "post2_the_app"]
          #expect(spec[:sha]).to eq "todo"
        end

        describe "Application Links" do
          before :each do
            allow(app).to receive(:linked_apps).with(config).and_return(['app1', 'app2'])
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

        describe "Dependency Links" do
          before :each do
            allow(app).to receive(:dependencies).with(config).and_return(['dep1', 'dep2'])
          end

          it "links to the container" do
            links = spec[:links]
            expect(links).to include ['container_for_convoy_id_dep1', 'dep1']
            expect(links).to include ['container_for_convoy_id_dep2', 'dep2']
          end
        end
      end
    end
  end
end

