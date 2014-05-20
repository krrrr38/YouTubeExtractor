json.url @url
json.set! :videos do
  json.array!(@videos) do |video|
    json.id video.youtube_id
    json.title video.title
  end
end
json.message @message