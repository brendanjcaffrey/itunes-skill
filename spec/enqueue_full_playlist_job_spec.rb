require 'rspec'
require 'sqlite3'
require 'sucker_punch'
require_relative 'spec_helper.rb'
require_relative '../src/enqueue_full_playlist_job.rb'
require_relative '../src/database.rb'
require_relative '../src/library.rb'

describe EnqueueFullPlaylistJob do
  it 'should append any tracks that aren\'t in the database already' do
    Database.create_test_database

    full_tracks = ['TRACK0', 'TRACK1', 'TRACK2', 'TRACK3', 'TRACK$']
    db = Database.new
    db.create_or_replace_user_playlist('USERID', ['TRACK0', 'TRACK1'])

    playlist = Database::UserPlaylist.new('a', 'b')
    expect(Library).to receive(:get_tracks_from_playlist).with(playlist).and_return(full_tracks)
    EnqueueFullPlaylistJob.new.perform('USERID', playlist, 2)

    expected_tracks = db.sqlite.execute('SELECT persistent_id FROM user_playlist_entry').map(&:first)
    expect(expected_tracks).to eq(full_tracks)
  end
end
