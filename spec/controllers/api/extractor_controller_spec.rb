require 'spec_helper'
require 'webmock/rspec'

describe Api::ExtractorController do

  describe "GET 'get'" do

    describe "without url parameter" do
      it "returns http bad_request" do
        get :get, format: :json
        response.should be_bad_request
        body = JSON.parse(response.body)
        body["message"].should eq "Invalid Argument"
      end
    end

    describe "extract unexist url" do
      let (:unexist_url) { sprintf("http://%s.example.com/youtubes", random_string) }
      before do
        stub_request(:get, unexist_url).to_return({:body => "", :status => 404})
        get :get, format: :json, url: unexist_url
      end

      describe "response" do
        it { response.should be_bad_request }
        it {
          body = JSON.parse(response.body)
          body["message"].should eq "Invalid Url"
        }
      end

      describe "after access with url" do
        subject { Page.where(url: unexist_url).first }

        it { should_not be_nil }
        its(:exist?) { should_not be_true }
      end
    end

    describe "extract non url param" do
      let (:non_url) { random_string }
      before { get :get, format: :json, url: non_url }

      describe "response" do
        it { response.should be_bad_request }
        it {
          body = JSON.parse(response.body)
          body["message"].should eq "Invalid Argument"
        }
      end

      describe "after access with non url" do
        subject { Page.where(url: non_url).first }

        it { should be_nil }
      end
    end

    describe "extract unparsed url" do
      let (:unparsed_url) { sprintf("http://%s.example.com/youtubes", random_string) }
      before do
        stub_request(:get, unparsed_url).to_return({:body => "<htm", :status => 200})
        get :get, format: :json, url: unparsed_url
      end

      describe "response" do
        it { response.should be_success }
        it {
          body = JSON.parse(response.body)
          body["url"].should eq unparsed_url
          body["message"].should eq "Cannot find any available videos"
        }
      end

      describe "after access with url" do
        subject { Page.where(url: unparsed_url).first }

        it { should_not be_nil }
        its(:exist?) { should be_true }
        its(:videos) { should be_empty }
      end
    end

    describe "extract parsed url with one video" do
      let (:youtube_id) { random_string }
      let (:parsed_url) { sprintf("http://%s.example.com/youtubes", random_string) }
      before do
        stub_request(:get, parsed_url).to_return({:body => generate_page(youtube_id), :status => 200})
        video_search_response = IO.read("./spec/data/html/you_tube/video_search.json")
        stub_request(:get, "https://gdata.youtube.com/feeds/api/videos/#{youtube_id}?alt=json&v=2")
          .to_return({:body => video_search_response, :status => 200})
        get :get, format: :json, url: parsed_url
      end

      describe "response" do
        let(:video) { Video.where(youtube_id: youtube_id).first }

        it { response.should be_success }
        it {
          body = JSON.parse(response.body)
          body["url"].should eq parsed_url
          body["videos"].should eq [{"id" => video.youtube_id, "title" => video.title}]
          body["message"].should be_nil
        }
      end

      describe "after access with url" do
        before { @video = Video.where(youtube_id: youtube_id).first }
        subject { Page.where(url: parsed_url).first }

        it { should_not be_nil }
        its(:exist?) { should be_true }
        its(:videos) { should eq [@video] }
        its(:video_relations) { should_not be_empty }
      end
    end
  end
end

def generate_page(id)
  "<html><head></head><body><a href=\"http://www.youtube.com/watch?v=#{id}\" target=\"_blank\">http://www.youtube.com/watch?v=#{id}</a></body></html>"
end
