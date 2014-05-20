require 'spec_unit_helper'
require 'html/client/factory'
require 'webmock/rspec'

class DummyFactory
  include HTML::Client::Factory
end

describe HTML::Client do
  let(:host) { "http://#{random_string}.krrrr38.com" }
  let(:client) { DummyFactory.new.client(host) }

  subject { @response }

  describe "access 200 url" do
    let(:body) { random_string }
    let(:path) { "/#{random_string}" }
    before do
      stub_request(:get, host + path).to_return({:body => body, :status => 200})
      @response = client.get(host + path)
    end

    its(:status) { should eq 200 }
    its(:success?) { should be_true }
    its(:body) { should eq body }
  end

  describe "access 404 url" do
    let(:path) { "/#{random_string}" }
    before do
      stub_request(:get, host + path).to_return({:status => 404})
      @response = client.get(host + path)
    end

    its(:status) { should eq 404 }
    its(:success?) { should_not be_true }
  end
end
