json.name current_user.name
json.set! :playlists do
  json.array!(@playlists) do |playlist|
    json.id playlist.playlist_id
    json.title playlist.title
    json.description playlist.description
  end
end
json.message @message
