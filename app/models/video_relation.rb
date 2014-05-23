# == Schema Information
#
# Table name: video_relations
#
#  id         :integer          not null, primary key
#  page_id    :integer          not null
#  video_id   :integer          not null
#  created_at :datetime
#  updated_at :datetime
#

class VideoRelation < ActiveRecord::Base
  belongs_to :page
  belongs_to :video
  validates :page_id, presence: true
  validates :video_id, presence: true
end
