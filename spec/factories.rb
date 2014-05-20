FactoryGirl.define do
  factory :page do
    sequence(:url) { |n| "http://#{n}.krrrr38.com" }
    is_exist true
    extracted_at Time.now
  end

  factory :video do
    sequence(:title) { |n| "video_title_#{n}" }
    sequence(:youtube_id) { |n| "youtubeid_#{n}" }
    is_embed true
    can_auto_play true
    is_syndicate true
    is_exist true
  end
end
