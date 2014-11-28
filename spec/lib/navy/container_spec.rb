require 'spec_helper'

describe Navy::Container do
  let(:specification) do
    {
      :container_name => 'the_container_name',
      :name => 'the_app_name',
      :type => "application"
    }
  end

  let(:dependencies) do
    ['dep1', 'dep2']
  end

  let(:etcd) do
    MockEtcd.new
  end

  subject do
    described_class.new :specification => specification,
                        :dependencies => dependencies
  end

  describe "#name" do
    it "is the container_name in the specification" do
      expect(subject.name).to eq 'the_container_name'
    end
  end

  describe "#app" do
    it "is the app name in the specification" do
      expect(subject.app).to eq 'the_app_name'
    end
  end

  describe "#daemon?" do
    context "when the type is application" do
      before :each do
        specification[:type] = "application"
      end
      
      it "is a daemon" do
        expect(subject.daemon?).to be true
      end
    end

    context "when the type is task" do
      before :each do
        specification[:type] = "task"
      end
      
      it "is a daemon" do
        expect(subject.daemon?).to be false
      end
    end
  end

  describe "#can_be_started?" do
    context "when there are no dependencies" do
      let(:dependencies) { [] }
      it "can be started" do
        expect(subject.can_be_started?(etcd)).to be true
      end
    end

    context "when the dependencies are not in desired state" do
      before :each do
        etcd.setJSON('/navy/containers/dep1/desired', {:state => :desired})
        etcd.setJSON('/navy/containers/dep1/actual', {:state => :not_desired})
      end

      it "cannot be started" do
        expect(subject.can_be_started?(etcd)).to be false
      end
    end

    context "when the dependencies are in desired state" do
      before :each do
        etcd.setJSON('/navy/containers/dep1/desired', {:state => :desired})
        etcd.setJSON('/navy/containers/dep1/actual', {:state => :desired})
        etcd.setJSON('/navy/containers/dep2/desired', {:state => :desired})
        etcd.setJSON('/navy/containers/dep2/actual', {:state => :desired})
      end

      it "can be started" do
        expect(subject.can_be_started?(etcd)).to be true
      end
    end
  end

  describe "#can_never_be_started?" do
    context "when there are no dependencies" do
      let(:dependencies) { [] }
      it "can *always* be started" do
        expect(subject.can_never_be_started?(etcd)).to be false
      end
    end

    context "when the dependencies exist" do
      context "when one of the dependencies is errored" do
        before :each do
          etcd.setJSON('/navy/containers/dep1/desired', {:state => :desired})
          etcd.setJSON('/navy/containers/dep1/actual', {:state => :error})
        end

        it "can *never* be started" do
          expect(subject.can_never_be_started?(etcd)).to be true
        end
      end

      context "when the dependencies are in non errored states" do
        before :each do
          etcd.setJSON('/navy/containers/dep1/desired', {:state => :desired})
          etcd.setJSON('/navy/containers/dep1/actual', {:state => :not_error})
        end

        it "can be *potentially* started" do
          expect(subject.can_never_be_started?(etcd)).to be false
        end

      end
    end
  end

  describe "#start" do
    let(:cmd) { Navy::CommandBuilder.new(subject).build }
    let(:launched) { [] }
    let(:success) { true }

    before :each do
      allow(Navy::Runner).to receive(:launch) do |cmd|
        launched << cmd
        success
      end
    end

    it "generates a command for the container and executes it" do
      subject.start
      expect(launched).to eq [cmd]
    end

    context "when the command succeeds" do
      it "returns true" do
        expect(subject.start).to be true
      end
    end

    context "when the command fails" do
      let(:success) { false }
      it "returns false" do
        expect(subject.start).to be false
      end
    end

    context "when it is a task" do
      before :each do
        specification[:type] = "task"
        specification[:cmds] = ["cmd1", "cmd2"]
      end

      it "runs each command" do
        subject.start
        expect(launched[0].last).to eq "cmd1"
        expect(launched[1].last).to eq "cmd2"
      end

      context "when one of the items fails" do
        let(:success) { false }

        it "returns false and does not run other tasks" do
          expect(subject.start).to be false
          expect(launched.length).to eq 1
        end
      end
    end
  end

  describe "#stop" do
    let(:cmd) { ["docker rm -f", "the_container_name"] }
    let(:launched) { [] }

    before :each do
      allow(Navy::Runner).to receive(:launch) do |cmd|
        launched << cmd
        true
      end
    end

    it "generates a rm command for the container and executes it" do
      subject.stop
      expect(launched).to eq [cmd]
    end
  end
end
