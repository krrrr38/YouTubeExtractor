require 'spec_helper'
require 'webmock/rspec'

module OAuth2
  class DummyResponse
    attr_accessor :error, :headers, :parsed, :body
  end
end

describe Api::PlaylistsController do
  before do
    users_default_response = IO.read("./spec/data/html/you_tube/users_default.xml")
    stub_request(:get, "http://gdata.youtube.com/feeds/api/users/default")
      .to_return(:status => 200, :body => users_default_response, :headers => {})
    stub_request(:post, "https://accounts.google.com/o/oauth2/token")
      .to_return(:status => 200, :body => "", :headers => {})
  end

  describe "GET playlists", type: :index do
    describe "without login user" do
      before { xhr :get, :index, format: :json }
      it { response.should be_bad_request }
      it { JSON.parse(response.body)["message"].should eq "Invalid Access" }
    end

    describe "with login user" do
      login_user

      describe "when youtube return 200 contents" do
        before do
          playlist_response = IO.read("./spec/data/html/you_tube/playlists.xml")
          stub_request(:get, "http://gdata.youtube.com/feeds/api/users/default/playlists?v=2.1")
            .to_return({:body => playlist_response, :status => 200})
          xhr :get, :index, format: :json
        end

        it { response.should be_success }
        describe "response body" do
          let(:body) { JSON.parse(response.body) }
          it { body["name"].should eq @user.name }
          it { body["message"].should be_nil }
          it { body["playlists"].should_not be_empty }

          describe "about playlist" do
            let(:playlist) { body["playlists"][0] }
            it { playlist["title"].should_not be_empty }
            it { playlist["description"].should_not be_nil }
          end
        end
      end

      describe "when oauth unavailable" do
        before do
          stub_request(:get, "http://gdata.youtube.com/feeds/api/users/#{@user.name}/playlists")
            .to_return({:body => "", :status => 403})
          allow_any_instance_of(Api::PlaylistsController).to receive(:fetch_youtube_with_auth_retry) { raise OAuth2::Error.new(OAuth2::DummyResponse.new) }
          xhr :get, :index, format: :json
        end

        it { response.should be_bad_request }

        let(:body) { JSON.parse(response.body) }
        it { body["message"].should eq "Authorization expired. Please Authenticate again." }
        it { body["reload"].should be_true }
      end

      describe "when youtube return 404" do
        before do
          @error_message = random_string
          stub_request(:get, "http://gdata.youtube.com/feeds/api/users/#{@user.name}/playlists")
            .to_return({:body => "", :status => 404})
          allow_any_instance_of(Api::PlaylistsController).to receive(:fetch_youtube_with_auth_retry) { raise YouTubeIt::ResourceNotFoundError.new(@error_message) }
          xhr :get, :index, format: :json
        end

        it { response.should be_bad_request }

        let(:body) { JSON.parse(response.body) }
        it { body["message"].should eq @error_message }
      end
    end
  end

  describe "POST playlists to add playlist", type: :create do
    describe "without login user" do
      before { xhr :post, :create, format: :json }
      it { response.should be_bad_request }
      it { JSON.parse(response.body)["message"].should eq "Invalid Access" }
    end

    describe "with login user" do
      login_user

      describe "without title param" do
        before { xhr :post, :create, format: :json }
        it { response.should be_bad_request }
        it { JSON.parse(response.body)["message"].should eq "Invalid Argument" }
      end

      describe "when youtube return 200 contents" do
        before do
          @title = random_string
          @description = random_string
          playlist_response = IO.read("./spec/data/html/you_tube/create_playlist.xml")
          stub_request(:post, "http://gdata.youtube.com/feeds/api/users/default/playlists")
            .to_return({:body => playlist_response, :status => 201})
          xhr :get, :create, format: :json, title: @title, description: @description
        end

        it { response.should be_success }
        describe "response body" do
          let(:body) { JSON.parse(response.body) }
          it { body["id"].should_not be_empty }
          it { body["title"].should_not be_empty }
          it { body["description"].should_not be_nil }
          it { body["message"].should match(/\Aplaylist .* created.\z/) }
        end
      end

      describe "when oauth unavailable" do
        before do
          stub_request(:POST, "http://gdata.youtube.com/feeds/api/users/#{@user.name}/playlists")
            .to_return({:body => "", :status => 403})
          allow_any_instance_of(Api::PlaylistsController).to receive(:fetch_youtube_with_auth_retry) { raise OAuth2::Error.new(OAuth2::DummyResponse.new) }
          xhr :get, :index, format: :json
        end

        it { response.should be_bad_request }

        let(:body) { JSON.parse(response.body) }
        it { body["message"].should eq "Authorization expired. Please Authenticate again." }
        it { body["reload"].should be_true }
      end
    end
  end

  describe "GET playlist", type: :show do
    describe "without login user" do
      before { xhr :get, :show, format: :json, id: random_string }
      it { response.should be_bad_request }
      it { JSON.parse(response.body)["message"].should eq "Invalid Access" }
    end

    describe "with login user" do
      login_user

      describe "when youtube return 200 contents" do
        before do
          playlist_response = IO.read("./spec/data/html/you_tube/playlist.xml")
          stub_request(:get, /http:\/\/gdata.youtube.com\/feeds\/api\/playlists\/.*/)
            .to_return({:body => playlist_response, :status => 200})
          xhr :get, :show, format: :json, id: random_string
        end

        it { response.should be_success }
        describe "response body" do
          let(:body) { JSON.parse(response.body) }
          it { body["name"].should eq @user.name }
          it { body["message"].should be_nil }
          it { body["videos"].should_not be_empty }

          describe "about videos" do
            let(:video) { body["videos"][0] }
            it { video["id"].should_not be_empty }
            it { video["title"].should_not be_empty }
            it { video["description"].should_not be_nil }
            it { video["playlist_entry_id"].should_not be_empty }
          end
        end
      end

      describe "when oauth unavailable" do
        before do
          stub_request(:get, /http:\/\/gdata.youtube.com\/feeds\/api\/playlists\/.*/)
            .to_return({:body => "", :status => 403})
          allow_any_instance_of(Api::PlaylistsController).to receive(:fetch_youtube_with_auth_retry) { raise OAuth2::Error.new(OAuth2::DummyResponse.new) }
          xhr :get, :show, format: :json, id: random_string
        end

        it { response.should be_bad_request }

        let(:body) { JSON.parse(response.body) }
        it { body["message"].should eq "Authorization expired. Please Authenticate again." }
        it { body["reload"].should be_true }
      end

      describe "when youtube return 404" do
        before do
          @error_message = random_string
          stub_request(:get, /http:\/\/gdata.youtube.com\/feeds\/api\/playlists\/.*/)
            .to_return({:body => "", :status => 404})
          allow_any_instance_of(Api::PlaylistsController).to receive(:fetch_youtube_with_auth_retry) { raise YouTubeIt::ResourceNotFoundError.new(@error_message) }
          xhr :get, :show, format: :json, id: random_string
        end

        it { response.should be_bad_request }

        let(:body) { JSON.parse(response.body) }
        it { body["message"].should eq @error_message }
      end
    end
  end

  describe "DELETE playlist", type: :destroy do
    describe "without login user" do
      before { xhr :delete, :destroy, format: :json, id: random_string }
      it { response.should be_bad_request }
      it { JSON.parse(response.body)["message"].should eq "Invalid Access" }
    end

    describe "with login user" do
      login_user

      describe "when youtube return 200 contents" do
        before do
          stub_request(:get, /http:\/\/gdata.youtube.com\/feeds\/api\/playlists\/.*/)

          stub_request(:delete, /http:\/\/gdata.youtube.com\/feeds\/api\/users\/default\/playlists\/.*/)
            .to_return(:status => 200, :body => "", :headers => {})
          xhr :delete, :destroy, format: :json, id: random_string
        end

        it { response.should be_success }
        describe "response body" do
          let(:body) { JSON.parse(response.body) }
          it { body["message"].should match(/\Aplaylist deleted successfully.\z/) }
        end
      end

      describe "when oauth unavailable" do
        before do
          stub_request(:delete, /http:\/\/gdata.youtube.com\/feeds\/api\/users\/default\/playlists\/.*/)
            .to_return({:body => "", :status => 403})
          allow_any_instance_of(Api::PlaylistsController).to receive(:fetch_youtube_with_auth_retry) { raise OAuth2::Error.new(OAuth2::DummyResponse.new) }
          xhr :delete, :destroy, format: :json, id: random_string
        end

        it { response.should be_bad_request }

        let(:body) { JSON.parse(response.body) }
        it { body["message"].should eq "Authorization expired. Please Authenticate again." }
        it { body["reload"].should be_true }
      end

      describe "when youtube return 404" do
        before do
          @error_message = random_string
          stub_request(:delete, /http:\/\/gdata.youtube.com\/feeds\/api\/users\/default\/playlists\/.*/)
            .to_return({:body => "", :status => 404})
          allow_any_instance_of(Api::PlaylistsController).to receive(:fetch_youtube_with_auth_retry) { raise YouTubeIt::ResourceNotFoundError.new(@error_message) }
          xhr :delete, :destroy, format: :json, id: random_string
        end

        it { response.should be_bad_request }

        let(:body) { JSON.parse(response.body) }
        it { body["message"].should eq @error_message }
      end
    end
  end

  describe "POST playlist to add video", type: :add_video do
    describe "without out user" do
      before { xhr :post, :add_video, format: :json, id: random_string }
      it { response.should be_bad_request }
      it { JSON.parse(response.body)["message"].should eq "Invalid Access" }
    end

    describe "with login user" do
      login_user

      describe "without playlist_title" do
        before do
          video = FactoryGirl.create(:video)
          xhr :post, :add_video, format: :json, id: video.youtube_id
        end
        it { response.should be_bad_request }
        it { JSON.parse(response.body)["message"].should eq "Invalid Argument" }
      end

      describe "without video id" do
        before { xhr :post, :add_video, format: :json, id: random_string, playlist_title: random_string }
        it { response.should be_bad_request }
        it { JSON.parse(response.body)["message"].should eq "Invalid Argument" }
      end

      describe "with unexist video id" do
        before { xhr :post, :add_video, format: :json, id: random_string, playlist_title: random_string, video_id: random_string }
        it { response.should be_bad_request }
        it { JSON.parse(response.body)["message"].should eq "Invalid Argument" }
      end

      describe "when youtube return 200 contents" do
        before do
          @playlist_title = random_string
          @video = FactoryGirl.create(:video)
          add_video_response = IO.read("./spec/data/html/you_tube/add_video_into_playlist.xml")
          stub_request(:post, /http:\/\/gdata.youtube.com\/feeds\/api\/playlists\/.*/)
            .to_return(:status => 201, :body => add_video_response, :headers => {})
          xhr :post, :add_video, format: :json, id: random_string, playlist_title: @playlist_title, video_id: @video.youtube_id
        end

        it { response.should be_success }
        describe "response body" do
          let(:body) { JSON.parse(response.body) }
          it { body["id"].should_not be_empty }
          it { body["title"].should_not be_empty }
          it { body["playlist_entry_id"].should_not be_empty }
          it { body["message"].should eq "#{@video.title} add into #{@playlist_title} successfully." }
        end
      end

      describe "when oauth unavailable" do
        before do
          stub_request(:post, /http:\/\/gdata.youtube.com\/feeds\/api\/playlists\/.*/)
            .to_return({:body => "", :status => 403})
          allow_any_instance_of(Api::PlaylistsController).to receive(:fetch_youtube_with_auth_retry) { raise OAuth2::Error.new(OAuth2::DummyResponse.new) }
          xhr :delete, :destroy, format: :json, id: random_string
        end

        it { response.should be_bad_request }

        let(:body) { JSON.parse(response.body) }
        it { body["message"].should eq "Authorization expired. Please Authenticate again." }
        it { body["reload"].should be_true }
      end
    end
  end

  describe "DELETE delete video from playlist", type: :delete_video do
    describe "without login user" do
      before { xhr :delete, :delete_video, format: :json, id: random_string, entry_id: random_string }
      it { response.should be_bad_request }
      it { JSON.parse(response.body)["message"].should eq "Invalid Access" }
    end

    describe "with login user" do
      login_user

      describe "when youtube return 200 contents" do
        before do
          stub_request(:delete, /http:\/\/gdata.youtube.com\/feeds\/api\/playlists\/.*\/.*/)
            .to_return(:status => 200, :body => "", :headers => {})
          xhr :delete, :delete_video, format: :json, id: random_string, entry_id: random_string
        end

        it { response.should be_success }
        describe "response body" do
          let(:body) { JSON.parse(response.body) }
          it { body["message"].should eq "video deleted successfully." }
        end
      end

      describe "when oauth unavailable" do
        before do
          stub_request(:delete, /http:\/\/gdata.youtube.com\/feeds\/api\/playlists\/.*\/.*/)
            .to_return({:body => "", :status => 403})
          allow_any_instance_of(Api::PlaylistsController).to receive(:fetch_youtube_with_auth_retry) { raise OAuth2::Error.new(OAuth2::DummyResponse.new) }
          xhr :delete, :delete_video, format: :json, id: random_string, entry_id: random_string
        end

        it { response.should be_bad_request }

        let(:body) { JSON.parse(response.body) }
        it { body["message"].should eq "Authorization expired. Please Authenticate again." }
        it { body["reload"].should be_true }
      end

      describe "when youtube return 404" do
        before do
          @error_message = random_string
          stub_request(:delete, /http:\/\/gdata.youtube.com\/feeds\/api\/playlists\/.*\/.*/)
            .to_return({:body => "", :status => 404})
          allow_any_instance_of(Api::PlaylistsController).to receive(:fetch_youtube_with_auth_retry) { raise YouTubeIt::ResourceNotFoundError.new(@error_message) }
          xhr :delete, :delete_video, format: :json, id: random_string, entry_id: random_string
        end

        it { response.should be_bad_request }

        let(:body) { JSON.parse(response.body) }
        it { body["message"].should eq @error_message }
      end
    end
  end
end
