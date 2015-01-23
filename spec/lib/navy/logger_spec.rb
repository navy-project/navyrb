require 'spec_helper'

describe Navy::Logger do
  let(:backend) do
    StringIO.new
  end

  let(:level) do
    :trace
  end

  subject do
    described_class.new(:backend => backend, :level => level)
  end

  describe "log levels" do
    it "allows to log different levels" do
      subject.trace "trace"
      subject.debug "debug"
      subject.info "info"
      subject.warn "warn"
      subject.error "error"
      subject.fatal "fatal"

      output = backend.string
      expect(output).to include "[TRAC] trace"
      expect(output).to include "[DEBU] debug"
      expect(output).to include "[INFO] info"
      expect(output).to include "[WARN] warn"
      expect(output).to include "[ERRO] error"
      expect(output).to include "[FATA] fatal"
    end

    context "log level info" do
      let(:level) do
        :info
      end

      it "does not log debug or trace" do
        subject.trace "trace"
        subject.debug "debug"
        subject.info "info"
        subject.warn "warn"
        subject.error "error"
        subject.fatal "fatal"

        output = backend.string
        expect(output).to_not include "[TRAC] trace"
        expect(output).to_not include "[DEBU] debug"
        expect(output).to include "[INFO] info"
        expect(output).to include "[WARN] warn"
        expect(output).to include "[ERRO] error"
        expect(output).to include "[FATA] fatal"
      end
    end
  end
end
