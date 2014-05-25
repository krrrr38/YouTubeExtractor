# -*- coding: utf-8 -*-
require 'youtube_it'

class Api::PlaylistsController < ApplicationController
  include CacheHelper
  before_filter :require_current_user  # only sign_in user available all api
  before_filter :require_playlist_id, only: [:show, :destroy, :add_video, :delete_video]
  before_filter :require_playlist_title, only: :add_video
  before_filter :require_video, only: :add_video
  before_filter :require_entry_id, only: :delete_video
  before_filter :get_youtube_client

  # get all playlists
  # GET      /api/playlists.json
  def index
    cache_key = generate_cache_key(user_name: current_user.name)
    @playlists = Rails.cache.read(cache_key)
    return if @playlists
    oauth_catch_renderer do
      @playlists = fetch_youtube_with_auth_retry(current_user, @client) do
        @client.playlists
      end
      Rails.cache.write(cache_key, @playlists, :expires_in => 60.seconds) if @playlists
    end
  end

  # create new playlist
  # POST     /api/playlists.json
  def create
    title = params[:title]
    description = params[:description] || ""

    return render json: { message: "Invalid Argument" }, status: :bad_request if !title || title.empty?

    oauth_catch_renderer do
      @playlist = fetch_youtube_with_auth_retry(current_user, @client) do
        @client.add_playlist(title: title, description: description)
      end
      @message = "playlist #{@playlist.title} created."
    end
  end

  # get playlist videos
  # GET      /api/playlists/:id.json
  def show
    cache_key = generate_cache_key(user_name: current_user.name, playlist_id: @playlist_id)

    @videos = Rails.cache.read(cache_key)
    return if @videos

    oauth_catch_renderer do
      videos = fetch_youtube_with_auth_retry(current_user, @client) do
        @client.playlist(@playlist_id).videos
      end
      create_unexist_videos(videos)
      @videos = videos.map {|video|
        {id: video.unique_id, title: video.title, description: video.description, playlist_entry_id: video.in_playlist_id}
      }
      Rails.cache.write(cache_key, @videos, :expires_in => 60.seconds)
    end
  end

  # delete playlist
  # DELETE   /api/playlists/:id.json
  def destroy
    oauth_catch_renderer do
      is_success  = fetch_youtube_with_auth_retry(current_user, @client) do
        @client.delete_playlist(@playlist_id)
      end
      if is_success
        @message = "playlist deleted successfully."
      else
        logger.error(generate_cache_key)
        logger.error("user:#{current_user.id} destroy:#{playlist_id}")
        @message = "playlist deleted failed..."
      end
    end
  end

  # add video into playlist
  # POST     /api/playlists/:id.json
  def add_video
    oauth_catch_renderer do
      response = fetch_youtube_with_auth_retry(current_user, @client) do
        @client.add_video_to_playlist(@playlist_id, @video.youtube_id)
      end

      if response[:code] == 201
        @entry_id = response[:playlist_entry_id]
        @message = "#{@video.title} add into #{@playlist_title} successfully."
      else
        logger.error(generate_cache_key)
        logger.error(response.inspect)
        @message = "#{@video.title} failed to add playlist..."
      end
    end
  end

  # delete video from playlist
  # DELETE   /api/playlists/:id/:entry_id.json
  def delete_video
    oauth_catch_renderer do
      is_success = fetch_youtube_with_auth_retry(current_user, @client) do
        @client.delete_video_from_playlist(@playlist_id, @entry_id)
      end
      if is_success
        @message = "video deleted successfully."
      else
        logger.error(generate_cache_key)
        logger.error("user:#{current_user.id} delete_video:#{@playlist_id}:#{@entry_id}")
        @message = "video deleted failed..."
      end
    end
  end

  private
  def require_current_user
    unless current_user
      render json: { message: "Invalid Access" }, status: :bad_request
    end
  end

  def require_playlist_id
    @playlist_id = params[:id]
    render json: { message: "Invalid Argument" }, status: :bad_request unless @playlist_id
  end

  def require_playlist_title
    @playlist_title= params[:playlist_title]
    render json: { message: "Invalid Argument" }, status: :bad_request unless @playlist_title
  end

  def require_video
    video_id = params[:video_id]
    @video = Video.where(youtube_id: video_id).first if video_id
    render json: { message: "Invalid Argument" }, status: :bad_request unless @video
  end

  def require_entry_id
    @entry_id = params[:entry_id]
    render json: { message: "Invalid Argument" }, status: :bad_request unless @entry_id
  end

  def get_youtube_client
    @client = YouTubeIt::OAuth2Client.new(
        client_access_token:  current_user.token,
        client_refresh_token: current_user.refresh_token,
        client_id:            Settings.google.client_id,
        client_secret:        Settings.google.client_secret,
        dev_key:              Settings.google.dev_key
    )
  end

  def create_unexist_videos(videos)
    exist_video_ids = Video.where(youtube_id: videos.map(&:unique_id)).pluck(:youtube_id)
    create_videos = videos.reject{|video| exist_video_ids.include?(video.unique_id)}.map do |api_video|
      if api_video.duration == 0
        Video.new(youtube_id: api_video.unique_id)
      else
        access_control = api_video.access_control
        Video.new(
          title:         api_video.title,
          youtube_id:    api_video.unique_id,
          is_embed:      access_control["embed"] == "allowed",
          can_auto_play: access_control["autoPlay"] == "allowed",
          is_syndicate:  access_control["syndicate"] == "allowed",
          is_exist:      true,
        )
      end
    end
    Video.import create_videos
  end

  def oauth_catch_renderer
    begin
      yield
    rescue OAuth2::Error
      render json: { message: "Authorization expired. Please Authenticate again.", reload: true }, status: :bad_request
    rescue => ex
      render json: { message: ex.message }, status: :bad_request
    end
  end

  # if token is expire, refresh token and save it
  # finally return fetch response
  def fetch_youtube_with_auth_retry(user, client, retry_count = 1)
    is_retry = false
    begin
      results = yield
      user.update(token: client.access_token.token) if is_retry
      results
    rescue OAuth2::Error => ex # except it, through all
      raise ex if retry_count <= 0
      client.refresh_access_token!
      is_retry = true
      retry_count -= 1
      retry
    end
  end
end
