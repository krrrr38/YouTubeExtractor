class Page < ActiveRecord::Base
  has_many :video_relations, dependent: :destroy
  has_many :videos, through: :video_relations, dependent: :destroy
  validates :url, presence: true

  alias_attribute :embed?, :is_embed
  alias_attribute :auto_play?, :can_auto_play
  alias_attribute :syndicate?, :is_syndicate
  alias_attribute :exist?, :is_exist

  def add_videos!(videos)
    self.video_relations.create!(videos.map {|video| {video_id: video.id}})
  end

  # return exist and available video
  def valid_videos
    self.videos.select{ |video|
      video.exist? && video.embed? && video.auto_play?
    }
  end
end
