require 'rubygems'
require 'google/apis/youtube_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'
require 'json'
require 'csv'
require 'retriable'

# Configurações de autenticação
REDIRECT_URI = 'http://localhost'
APPLICATION_NAME = 'YouTube Playlist App'
CLIENT_SECRETS_PATH = 'client_secret.json'
CREDENTIALS_PATH = 'credentials.json'
SCOPE = Google::Apis::YoutubeV3::AUTH_YOUTUBE_FORCE_SSL


def authorize
  FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

  client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)

  unless credentials
    puts "Abra este link no navegador e autorize o app:"
    url = authorizer.get_authorization_url(base_url: REDIRECT_URI)
    puts url
    print "Cole o código de autorização aqui: "
    code = gets.chomp
    credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: REDIRECT_URI)
  end

  credentials
end

service = Google::Apis::YoutubeV3::YouTubeService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

def search_and_add_to_playlist(service, playlist_id, title)
  Retriable.retriable(tries: 5, base_interval: 2, max_interval: 10) do
    begin
      search_response = service.list_searches('snippet', q: title, max_results: 1)

      if search_response.items.empty?
        puts "Nenhum vídeo encontrado para '#{title}'"
        return title, 'not_found'
      end

      video_id = search_response.items.first.id.video_id

      service.insert_playlist_item(
        'snippet',
        Google::Apis::YoutubeV3::PlaylistItem.new(
          snippet: Google::Apis::YoutubeV3::PlaylistItemSnippet.new(
            playlist_id: playlist_id,
            resource_id: Google::Apis::YoutubeV3::ResourceId.new(
              kind: 'youtube#video',
              video_id: video_id
            )
          )
        )
      )

      puts "Adicionada: #{title}"
      return title, 'added'

    rescue Google::Apis::ClientError => e
      if e.status_code == 503
        puts "Erro 503: Serviço indisponível. Tentando novamente..."
        raise e
      elsif e.message.include?('quotaExceeded')
        puts "Erro de cota excedida para '#{title}'. Atualizando CSV."
        return title, 'quota_exceeded'
      else
        puts "Erro ao adicionar o vídeo '#{title}': #{e.message}"
        return title, 'failed'
      end
    end
  end
end

def update_csv(music_list, status, file_path)
  CSV.open(file_path, 'w', write_headers: true, headers: ['title', 'status']) do |csv|
    music_list.each do |music|
      csv << [music[:title], status[music[:title]]]
    end
  end
end

music_list = []
status = {}

if File.exist?('tracks.csv')
  CSV.foreach("tracks.csv", headers: true) do |row|
    title = row['title']
    music_list << { title: title }
    status[title] = row['status'] || 'pending'
  end
else
  CSV.foreach("tracks.csv", headers: false) do |row|
    title = row['title']
    music_list << { title: title }
    status[title] = 'pending'
  end
end

playlist_id = 'PLSgutm9kgzH2h_5lstDgDIFTCXa__Ia5W'

music_list.each do |music|
  next if status[music[:title]] == 'added'
  title, result = search_and_add_to_playlist(service, playlist_id, music[:title])
  status[title] = result
end

update_csv(music_list, status, 'tracks.csv')
