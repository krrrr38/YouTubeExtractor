class VideoRelation < ActiveRecord::Base
  belongs_to :page
  belongs_to :video
  validates :page_id, presence: true
  validates :video_id, presence: true
end
