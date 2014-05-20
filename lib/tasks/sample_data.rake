namespace :db do
  desc "Fill database with sample data"
  task populate: :environment do
    make_pages
    make_videos
    make_video_relations
  end
end

def make_pages
  3.times do |n|
    Page.create!(
      url: sprintf("http://%s.krrrr38.com/%d", ('a'..'z').to_a.sample(5).join, n),
      is_exist: true,
      extracted_at: Time.now
    );
  end
end

def make_videos
  20.times do |n|
    Video.create!(
      title: "title_#{n}",
      youtube_id: "youtube_id_#{n}",
      is_embed: n % 3 == 0,
      can_auto_play: n % 3 == 1,
      is_syndicate: true,
      is_exist: n % 4 != 3,
      is_crowled: true,
    )
  end
end

def make_video_relations
  pages = Page.all
  videos = Video.all
  pages.each { |page|
    page.add_videos!(videos.sample(8))
  }
end
