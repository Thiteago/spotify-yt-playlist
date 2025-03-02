require 'rspotify'
require 'dotenv/load'
require 'byebug'
require 'csv'

RSpotify.authenticate(ENV['SPOTIFY_CLIENT_ID'], ENV['SPOTIFY_CLIENT_SECRET'])

playlist_id = ENV['SPOTIFY_PLAYLIST_ID']
playlist = RSpotify::Playlist.find('spotify', playlist_id)

tracks = []
offset = 0

loop do
  page = playlist.tracks(offset: offset, limit: 50)
  break if page.empty?

  page.each do |track|
    tracks << [track.name + ' ' + track.artists.map(&:name).join(', ') + ' live']
  end

  offset += 50
end

CSV.open('tracks.csv', 'wb') do |csv|
  tracks.each { |track| csv << track }
end
