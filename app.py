from flask import Flask, jsonify, request
import logging
import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
import pandas as pd
from sklearn.decomposition import TruncatedSVD
import numpy as np
from flask import Flask
from flask_cors import CORS

app = Flask(__name__)
CORS(app)


# Initialize Spotify API client
client_credentials_manager = SpotifyClientCredentials(client_id='c3661ff72f704f1a8d7f5c102653c3c1', client_secret='288b8ddb13b1402db562b7e884d5323e')
sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager)

# Load your dataset from the CSV file
data = pd.read_csv('data.csv')

# Set up logging
logging.basicConfig(level=logging.INFO)

# Train collaborative filtering model
def train_collaborative_filtering_model(data):
    # Select relevant features for training
    features = data[['acousticness', 'danceability', 'energy', 'instrumentalness', 'liveness', 'loudness', 'speechiness', 'tempo', 'valence']]

    # Apply Singular Value Decomposition (SVD) for dimensionality reduction
    svd = TruncatedSVD(n_components=min(features.shape) - 1)  # Use the smaller dimension
    svd.fit(features)

    return svd

# Function to retrieve tracks based on dance style
def get_tracks_for_dance_style(dance_style):
    # Define the parameters for the recommendations query
    seed_genres = [dance_style]  # Use the dance style as the seed genre
    limit = 10  # Number of tracks to retrieve

    # Make the request to Spotify's Recommendations API
    recommendations = sp.recommendations(seed_genres=seed_genres, limit=limit)

    # Extract the track IDs from the recommendations
    track_ids = [track['id'] for track in recommendations['tracks']]

    return track_ids

# Function to recommend tracks based on dance style
def recommend_tracks_for_dance_style(dance_style, svd_model):
    # Retrieve tracks for the given dance style
    track_ids = get_tracks_for_dance_style(dance_style)

    # Convert the list of arrays into a single NumPy array
    track_ids = np.hstack(track_ids)

    # Retrieve audio features for the recommended tracks
    track_features = [sp.audio_features(track_id)[0] for track_id in track_ids]

    # Select relevant features for the recommended tracks
    track_features = pd.DataFrame(track_features)[['acousticness', 'danceability', 'energy', 'instrumentalness', 'liveness', 'loudness', 'speechiness', 'tempo', 'valence']]

    # Transform the features using the trained SVD model
    transformed_features = svd_model.transform(track_features)

    # Calculate the similarity scores based on transformed features
    similarity_scores = np.dot(transformed_features, svd_model.components_)

    # Sort the track IDs based on similarity scores
    sorted_indices = np.argsort(similarity_scores)[::-1]

    # Retrieve the recommended tracks using sorted indices
    recommended_tracks = track_ids[sorted_indices]

    return recommended_tracks 

# Function to search song by ID
def search_song_by_id(track_id):
    # Check if track_id is already a string or a single-element array
    if isinstance(track_id, str):
        track_info = sp.track(track_id)
    elif isinstance(track_id, np.ndarray) and track_id.size == 1:
        # If track_id is a single-element array, convert it to string
        track_info = sp.track(track_id.item())
    else:
        # Convert track_id to list of strings
        track_ids = track_id.tolist()
        # Retrieve track information for each track ID
        track_info = [sp.track(tid) for tid in track_ids]

    # Process track information and return relevant details
    if isinstance(track_info, list):
        # If multiple track information is retrieved
        song_info = []
        for info in track_info:
            song_name = info['name']
            artists = ', '.join([artist['name'] for artist in info['artists']])
            album = info['album']['name']
            song_info.append({'song_name': song_name, 'artists': artists, 'album': album})
        return song_info
    else:
        # If single track information is retrieved
        song_name = track_info['name']
        artists = ', '.join([artist['name'] for artist in track_info['artists']])
        album = track_info['album']['name']
        return {'song_name': song_name, 'artists': artists, 'album': album}

# Route for recommending songs based on dance style
@app.route('/recommendations/<dance_style>', methods=['GET', 'POST'])
def recommend_songs(dance_style):
    logging.info(f"Received request for dance style: {dance_style}")

    # Train collaborative filtering model
    svd_model = train_collaborative_filtering_model(data)

    # Recommend tracks for the provided dance style
    recommended_tracks = recommend_tracks_for_dance_style(dance_style, svd_model)

    # Search for song details and format the response
    recommended_songs = []
    for track_id in recommended_tracks:
        song_info = search_song_by_id(track_id)
        recommended_songs.append(song_info)

    logging.info("Recommended Songs:")
    logging.info(recommended_songs)

    return jsonify({'recommended_songs': recommended_songs})

if __name__ == '__main__':
    app.run(debug=True)