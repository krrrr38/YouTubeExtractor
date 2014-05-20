require 'html/you_tube/extractor'
require 'html/client/factory'
require 'parallel'

class Api::ExtractorController < ApplicationController
  include HTML::YouTube::Extractor
  include HTML::Client::Factory
  before_filter :require_url

  # return youtube data which are included in the url
  # it excludes id which has already fetch and unexist.
  def get
    page = Page.where(url: @url).first

    # if not crawled page, crawl it
    unless page
      uri = URI(@url)
      client = self.client("#{uri.scheme}://#{uri.host}")

      begin
        response = client.get(uri.request_uri)
        raise unless response.success?
      rescue
        Page.create(url: @url, is_exist: false, extracted_at: Time.now)
        return render json: { message: "Invalid Url" }, status: :bad_request
      end

      page = Page.create(url: @url, is_exist: true, extracted_at: Time.now)
      extracted_ids = self.extract_ids(response.body)

      # crawl youtube video titles if not have complete them
      exist_videos    = Video.where(youtube_id: extracted_ids)
      exist_video_ids = exist_videos.map(&:id)
      unexist_ids     = extracted_ids.reject{|id| exist_video_ids.include?(id) }
      unexist_videos = unexist_ids.map {|id| crawl_youtube_video(id) }
      # XXX why cannot work????
      # unexist_videos = Parallel.map(unexist_ids) do |id|
      #   ActiveRecord::Base.connection_pool.with_connection do
      #     crawl_youtube_video(id)
      #   end
      # end
      page.add_videos!(exist_videos + unexist_videos)
    end

    if page.exist?
      @videos = page.valid_videos
      @message = "Cannot find any available videos" if @videos.empty?
    else
      return render json: { message: "Invalid Url" }, status: :bad_request
    end
  end

  private
  def require_url
    @url = params[:url]
    if !@url || @url.empty? || !@url.match(/^https?:\/\/.*/)
      render json: { message: "Invalid Argument" }, status: :bad_request
    end
  end

  def crawl_youtube_video(id)
    client = self.client("https://gdata.youtube.com")
    path = "/feeds/api/videos/#{id}?v=2&alt=json"
    response = client.get path, v: 2, alt: :json

    if response.success?
      Video.create_from_video_search_response(id, JSON.parse(response.body))
    else
      Video.create({youtube_id: id, is_exist: false})
    end
  end
end
