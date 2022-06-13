terraform {
  required_providers {
    spotify = {
      version = "~> 0.2.6"
      source  = "conradludgate/spotify"
    }
  }
}

variable "spotify_api_key" {
  type = string
  description = "Set this as the APIKey that the authorization proxy server outputs"
}

provider "spotify" {
  api_key = var.spotify_api_key
}

data "spotify_search_track" "by_artist" {
  artist = "Dolly Parton"
  #  album = "Jolene"
  #  name  = "Early Morning Breeze"
}

resource "spotify_playlist" "playlist" {
  name        = "Terraform Summer Playlist"
  description = "This playlist was created by Terraform"
  public      = true

  tracks = [
    data.spotify_search_track.by_artist.tracks[0].id,
    data.spotify_search_track.by_artist.tracks[1].id,
    data.spotify_search_track.by_artist.tracks[2].id,
    data.spotify_search_track.by_artist.tracks[3].id,
    data.spotify_search_track.by_artist.tracks[4].id,
    data.spotify_search_track.by_artist.tracks[5].id,
    data.spotify_search_track.by_artist.tracks[6].id,
    data.spotify_search_track.by_artist.tracks[7].id,
    data.spotify_search_track.by_artist.tracks[8].id,
    data.spotify_search_track.by_artist.tracks[9].id
  ]
}
<<<<<<< HEAD

data "spotify_search_track" "by_artist" {
  artists = ["Rainbow Kitten Surprise"]
  #  album = "Jolene"
  #  name  = "Early Morning Breeze"
}

output "tracks" {
  value = data.spotify_search_track.by_artist.tracks
}
=======
>>>>>>> 22d1416c2c45e363076de1f42399f9bedc7842bc
