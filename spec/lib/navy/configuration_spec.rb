require 'spec_helper'

describe Navy::Configuration do

  describe ".from_file" do
    it "loads from the file" do
      expect(YAML).to receive(:load_file).with('the_file.yml').and_return('YAML')
      expect(described_class).to receive(:new).with('YAML')

      described_class.from_file('the_file.yml')
    end
  end

  let(:yaml) do
    <<-YAML
    apps:
      app1:
      app2:
    environments:
      one:
        dependencies:
          dep1:
          dep2:
        pre:
          app1:
            - pretask1
            - pretask2
        post:
        docker:
          app1: --some argument
      two:
        dependencies:
          twodep1:
          twodep2:
        post:
          app2:
            - posttask1
            - posttask2
        docker:
          app1: --different argument
    YAML
  end

  subject { described_class.from_string(yaml) }

  describe "#container_name" do
    it "returns the name the container will have" do
      name = subject.container_name('app1', :convoy => 'convoy')
      expect(name).to eq 'convoy_app1'
    end

    it "uses given mode" do
      name = subject.container_name('app1', :convoy => 'convoy', :mode => 'the_mode')
      expect(name).to eq 'convoy_app1_the_mode'
    end

    it "uses given scale" do
      name = subject.container_name('app1', :convoy => 'convoy', :scale => 2)
      expect(name).to eq 'convoy_app1_2'
    end
  end

  describe "Applications" do

    describe "#apps" do
      it "yields an application for each application in the config" do
        apps = []
        subject.apps do |app|
          apps << app
        end

        names = apps.map &:name

        expect(names).to include 'app1'
        expect(names).to include 'app2'
      end
    end

    describe "#applications" do
      it "returns array of app names" do
        expect(subject.applications).to eq ['app1', 'app2']
      end
    end

    describe "#find_app" do
      it "finds the an application by the given name" do
        apps = []
        subject.apps { |a| apps << a }

        expect(subject.find_app(apps[1].name)).to equal apps[1]
      end
    end

  end

  describe "Dependencies" do
    before :each do
      subject.set_env('one')
    end

    describe "#dependencies" do
      it "yields and application for each defined dependency in the config" do
        apps = []
        subject.dependencies { |a| apps << a }

        names = apps.map &:name

        expect(names).to include 'dep1'
        expect(names).to include 'dep2'
      end

      it "uses the given environment" do
        subject.set_env('two')
        apps = []
        subject.dependencies { |a| apps << a.name }

        expect(apps).to eq ['twodep1', 'twodep2']
      end
    end
  end

  describe "Tasks" do
    before :each do
      subject.set_env('one')
    end

    describe "#pre_tasks" do
      it "returns an array of tasks for given app name" do
        cmds = subject.pre_tasks('app1')
        expect(cmds).to eq ['pretask1', 'pretask2']
      end

      it "uses the environment" do
        subject.set_env('two')
        cmds = subject.pre_tasks('app1')
        expect(cmds).to be_empty
      end
    end

    describe "#post_tasks" do
      it "returns an array of tasks for given app name" do
        subject.set_env('two')
        cmds = subject.post_tasks('app2')
        expect(cmds).to eq ['posttask1', 'posttask2']
      end

      it "uses the environment" do
        cmds = subject.post_tasks('app2')
        expect(cmds).to be_empty
      end
    end
  end

  describe "Docker Arguments" do
    before :each do
      subject.set_env('one')
    end

    it "gives the docker args from the environment for given app" do
      expect(subject.docker_args('app1')).to eq "--some argument"
      subject.set_env('two')
      expect(subject.docker_args('app1')).to eq "--different argument"
    end
  end
end
