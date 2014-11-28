require 'spec_helper'

describe Navy::Runner do
  let(:cmd) { ['the', 'command'] }

  describe ".launch" do
    let(:success) { true }
    let(:status) { double :success? => success }

    before :each do
      allow(Open3).to receive(:capture3) do |cmd|
        @executed = cmd
        ["stdout", "stderr", status]
      end
    end

    it "executes the command" do
      described_class.launch cmd
      expect(@executed).to eq "the command"
    end

    context "when the execution succeeds" do
      it "returns true" do
        expect(described_class.launch(cmd)).to be true
      end
    end

    context "when the execution fails" do
      let(:success) { false }

      it "returns false" do
        expect(described_class.launch(cmd)).to be false
      end
    end
  end
end
