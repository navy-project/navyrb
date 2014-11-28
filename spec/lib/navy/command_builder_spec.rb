require 'spec_helper'

describe Navy::CommandBuilder do

  let(:specification) do
    {
      :env => {"VAR1" => "val1", "VAR2" => "val2"},
      :links => [["fromcontainer", "toalias"], ["othercontainer", "otheralias"]],
      :volumes_from => ["somecontainer"],
      :name => "theapp",
      :container_name => "the_app_container_name",
      :image => "the_image",
      :docker_args => "other docker args",
      :type => "application",
      :cmd => "the specified command"
    }
  end

  let(:container) do
    Navy::Container.new :specification => specification
  end

  subject do
    described_class.new container
  end

  describe "#build" do
    let(:cmd) { subject.build }

    context "when the type is application" do
      it"runs the container in daemon mode" do
        expect(cmd.first).to eq "docker run -d"
      end
    end

    context "when the type is task" do
      before :each do
        container.specification[:type] = "task"
      end

      it"runs the container in throw away mode" do
        expect(cmd.first).to eq "docker run --rm"
      end
    end

    it "starts the appropriate image" do
      expect(cmd[-2]).to eq "the_image"
    end

    it "executes specified command" do
      expect(cmd[-1]).to eq "the specified command"
    end

    context "when there's a given command" do
      let(:cmd) { subject.build :command => "the command to run" }

      it"starts the image with overridden command" do
        expect(cmd[-2]).to eq "the_image"
        expect(cmd[-1]).to eq "the command to run"
      end
    end

    it "gives the container specified name" do
      expect(cmd).to include "--name the_app_container_name"
    end

    it "sets specified environment variables" do
      expect(cmd).to include "-e=\"VAR1=val1\""
      expect(cmd).to include "-e=\"VAR2=val2\""
    end
    
    it "sets specified links" do
      expect(cmd).to include "--link=fromcontainer:toalias"
      expect(cmd).to include "--link=othercontainer:otheralias"
    end

    it "uses volumes from specified" do
      expect(cmd).to include "--volumes-from=somecontainer"
    end

    it "includes any additional docker args" do
      expect(cmd).to include "other docker args"
    end
  end
end
