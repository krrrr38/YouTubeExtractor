json.name current_user.name
json.playlist_id @playlist_id
json.set! :videos do
  json.array!(@videos) do |video|
    json.extract! video, :id, :title, :description, :playlist_entry_id
  end
end
json.message @message
