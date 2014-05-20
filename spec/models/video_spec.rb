require 'spec_helper'
require 'json'

describe Video do
  before do
    @video = FactoryGirl.create(:video)
  end

  subject { @video }

  it { should respond_to(:title) }
  it { should respond_to(:youtube_id) }
  it { should respond_to(:embed?) }
  it { should respond_to(:auto_play?) }
  it { should respond_to(:syndicate?) }
  it { should respond_to(:exist?) }
  it { should be_valid }

  describe "lack of attributes" do
    before { @video.youtube_id = "" }
    it { should_not be_valid }
  end

  describe "create from video search response" do
    let(:youtube_id) { random_string }
    before do
      body = IO.read("./spec/data/html/you_tube/video_search.json")
      @video = Video.create_from_video_search_response(youtube_id, JSON.parse(body))
    end

    its(:title) { should eq "Leisure Central - Midnight Ball [Noctune No.3 Dream of Love] (Franz Liszt)" }
    its(:youtube_id) { should eq youtube_id }
    its(:embed?) { should be_true }
    its(:auto_play?) { should be_true }
    its(:syndicate?) { should_not be_true }
    its(:exist?) { should be_true }
  end
end
