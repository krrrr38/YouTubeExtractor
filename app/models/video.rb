class Video < ActiveRecord::Base
  has_many :video_relations
  validates :youtube_id, presence: true

  alias_attribute :embed?, :is_embed
  alias_attribute :auto_play?, :can_auto_play
  alias_attribute :syndicate?, :is_syndicate
  alias_attribute :exist?, :is_exist

  def self.create_from_video_search_response(id, json)
    entry = json["entry"]
    access_control = {
      is_embed: false,
      can_auto_play: false,
      is_syndicate: false
    }
    entry["yt$accessControl"].each {|control|
      next unless control["permission"] == "allowed"
      case control["action"]
      when "embed"
          access_control[:is_embed] = true
      when "autoPlay"
        access_control[:can_auto_play] = true
      when "syndicate"
        access_control[:is_syndicate] = true
      end
    }
    self.create({
        title: entry["title"]["$t"],
        youtube_id: id,
        is_exist: true,
      }.merge access_control)
  end
end
