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

  factory :user do
    sequence(:uid) { |n| "uid_#{n}" }
    sequence(:name) { |n| "name_#{n}" }
    sequence(:email) { |n| "email_#{n}@local.krrrr38.com" }
    sequence(:image_path) { |n| "http://tekitou_#{n}.krrrr38.com/#{n}.jpg" }
    sequence(:password) { |n| "password_#{n}" }
    sequence(:token) { |n| "token_#{n}" }
    sequence(:refresh_token) { |n| "refresh_token_#{n}" }
    expires_at 6.hours.since
    expires true
  end
end
