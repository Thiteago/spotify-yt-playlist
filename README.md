# YouTube Playlist Sync Live Songs

This script allows you to synchronize a playlist from Spotify with YouTube by extracting tracks from a Spotify playlist, searching for them on YouTube, and adding them to a specified playlist. It also handles API quota limits by updating the CSV file with the status of each song, ensuring that failed attempts can be retried later. It's important to say, the script will search for the live version of an specific song. (You can make a fork and change it if you want).

## Features

- Extracts songs from a Spotify playlist.
- Reads a list of songs from a CSV file.
- Searches for songs on YouTube and adds them to a specified playlist.
- Updates the CSV file with a "done" status for successfully added songs.
- Retries failed attempts in the next run, avoiding repeated API calls for completed tasks.
- Handles API quota limits by skipping songs when limits are exceeded.

## Requirements

- Ruby (3.1.3 recommended)
- Google API Client for Ruby
- RSpotify gem for Spotify authentication
- A YouTube API key and OAuth credentials
- A Spotify Developer account and API credentials
- CSV file with song titles

## Setup

### 1. Install Dependencies

Make sure you have Ruby installed. Then, install the required gems:

```sh
bundle install
```

### 2. Configure Spotify API Credentials

- Create a Spotify Developer account at [Spotify Developer Dashboard](https://developer.spotify.com/dashboard/).
- Create an application and retrieve your `Client ID` and `Client Secret`.
- Set up your environment variables by creating a `.env` file in the project root and adding:

```sh
SPOTIFY_CLIENT_ID=your_client_id
SPOTIFY_CLIENT_SECRET=your_client_secret
SPOTIFY_PLAYLIST_ID=your_playlist_id
```

### 3. Extract Songs from Spotify

Run the following script to fetch songs from your Spotify playlist and save them to `tracks.csv`:

```sh
ruby spotify_playlist.rb
```

### 4. Configure YouTube API Credentials

- Create a project in the [Google Cloud Console](https://console.cloud.google.com/).
- Enable the YouTube Data API v3.
- Generate OAuth 2.0 credentials and download the `client_secret.json` file.
- Place the `client_secret.json` file in the script directory.

### 5. Authentication

The script will prompt you to authenticate via a web link the first time you run it. Follow the instructions to grant access to your YouTube account.

## Usage

1. Ensure that `tracks.csv` is populated with song titles in the following format:

```csv
title,status
"Song Title 1",
"Song Title 2",
```

2. Run the script to add songs to the YouTube playlist:

```sh
ruby add_to_yt.rb
```

3. The script will:
   - Search for the song on YouTube.
   - Add it to the playlist.
   - Update `tracks.csv` by marking successful entries as `done`.
   - Keep failed entries in the CSV for future retries.

## Handling API Quota Limits

If the script encounters a `quotaExceeded` error, it will:

- Stop adding new songs.
- Preserve failed attempts in `tracks.csv`.
- Allow retrying failed songs in the next execution.

## Notes

- Ensure your API quota is sufficient for bulk operations.
- The script may take some time depending on the number of songs.
- Running it daily is recommended to bypass quota limits effectively.

## License

This project is open-source and free to use.

