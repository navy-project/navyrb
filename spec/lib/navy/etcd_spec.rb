require 'spec_helper'
require 'webmock/rspec'

describe Navy::Etcd do
  let(:options) do
    {:host => 'etcdhost', :port => '1234'}
  end

  let(:example_record) do
    <<-JSON
    {
      "action":"The Action",
      "node": {
           "createdIndex": 1,
           "key": "/akey",
           "modifiedIndex": 2,
           "value": "New Value"
        },
      "prevNode": {
            "createdIndex": 1,
            "key": "/akey",
            "value": "Prev Value",
            "modifiedIndex": 3
        }
    }
    JSON
  end

  let(:example_json_record) do
    <<-JSON
    {
      "action":"The Action",
      "node": {
           "createdIndex": 1,
           "key": "/akey",
           "modifiedIndex": 2,
           "value": "{\\"key\\":\\"value\\"}"
        },
      "prevNode": {
            "createdIndex": 1,
            "key": "/akey",
            "value": "Prev Value",
            "modifiedIndex": 3
        }
    }
    JSON
  end

  let(:example_headers) do
    {
      "X-Etcd-Index" => "999"
    }
  end

  subject { described_class.client options }

  describe "Retrieval" do
    describe "#get" do
      before :each do
        @request = stub_request(:get, 'http://etcdhost:1234/v2/keys/some/key').
          to_return(:body => example_record, :headers => example_headers)
      end

      it "fetches a response from the given key" do
        record = subject.get('/some/key')

        #expect(@request).to have_been_made

        expect(record.key).to eq '/akey'
        expect(record.etcd_index).to be 999
        expect(record.action).to eq "The Action"
        expect(record.node.createdIndex).to eq 1
        expect(record.node.modifiedIndex).to eq 2
        expect(record.node.value).to eq "New Value"
        expect(record.prevNode.value).to eq "Prev Value"
      end
    end

    describe "#getJSON" do
      before :each do
        @request = stub_request(:get, 'http://etcdhost:1234/v2/keys/some/key').
          to_return(:body => example_json_record, :headers => example_headers)
      end

      it "fetches and parses as JSON the given jey" do
        hash = subject.getJSON('/some/key')
        #expect(@request).to have_been_made

        expect(hash['key']).to eq 'value'
      end
    end

    describe "#watch" do
      before :each do
        @request = stub_request(:get, 'http://etcdhost:1234/v2/keys/some/key?wait=true').
          to_return(:body => example_record, :headers => example_headers)
      end

      it "fetches with a wait" do
        record = subject.watch('/some/key')
        #expect(@request).to have_been_made
      end
    end

    describe "#ls" do
      let(:exampledir) do
        {
          :node => {
            :nodes => [
              {:key => '/some/dir/item1'},
              {:key => '/some/dir/item2'}
            ]
          }
        }.to_json
      end

      before :each do
        @request = stub_request(:get, 'http://etcdhost:1234/v2/keys/some/dir').
          to_return(:body => exampledir)
      end

      it "returns the keys in the given directory" do
        keys = subject.ls('/some/dir')
        #expect(@request).to have_been_made
        expect(keys).to include '/some/dir/item1'
        expect(keys).to include '/some/dir/item2'
        expect(keys.length).to eq 2
      end
    end

  end

  describe "Storage" do
    describe "#setJSON" do
      let(:data) do
        data = {:some => :json, :data => [:here]}
      end

      before :each do
        @request = stub_request(:put, 'http://etcdhost:1234/v2/keys/some/json/key').
          with(:body => {:value => data.to_json})
      end

      it "stores JSON encoded value at given key" do
        subject.setJSON('/some/json/key', data)
        #expect(@request).to have_been_made
      end
    end

    describe "#delete" do
      before :each do
        @request = stub_request(:delete, 'http://etcdhost:1234/v2/keys/some/key?with=param').to_return(:status => 202)
      end

      it "deletes the specified key" do
        result = subject.delete('/some/key', :with => :param)
        expect(@request).to have_been_made
        expect(result).to be true
      end

      context "when the key is missing" do
        before :each do
          @request = stub_request(:delete, 'http://etcdhost:1234/v2/keys/some/key?with=param').to_return(:status => 404)
        end

        it "returns false" do
          result = subject.delete('/some/key', :with => :param)
          expect(result).to be false
        end
      end
    end

    describe "#set" do
      let(:data) { "some data " }

      before :each do
        @request = stub_request(:put, 'http://etcdhost:1234/v2/keys/some/data/value').
          with(:body => {:value => data })
      end

      it "stores the string at the given value" do
        subject.set('/some/data/value', data)
        #expect(@request).to have_been_made
      end
    end

    describe "#queueJSON" do
      let(:data) { {:some => :json } }

      before :each do
        @request = stub_request(:post, 'http://etcdhost:1234/v2/keys/some/queue').
          with(:body => {:value => data.to_json })
      end

      it "stores the string at the given value" do
        subject.queueJSON('/some/queue', data)
        expect(@request).to have_been_made
      end
    end
  end

end
