require 'rspec'
require 'sqlite3'
require 'sucker_punch'
require_relative '../src/custom_intents.rb'
require_relative '../src/library.rb'
require_relative '../src/enqueue_full_playlist_job.rb'

describe CustomIntents do
  before :each do
    Database.create_test_database
    @db = Database.new
    @custom_intents = CustomIntents.new(@db)
    @builder = instance_double('ResponseBuilder')
    @tracks = ['TRACK0', 'TRACK1', 'TRACK2']
  end

  def expect_enqueue_track0
    expect(Library).to receive(:get_start_milliseconds_for_track_id).with('TRACK0').and_return(333)
    expect(@builder).to receive(:add_play_directive).with('USERID', 'TRACK0', 333)
    expect(@builder).to receive(:add_plain_text_speech).with('OK')
  end

  def expect_enqueued_tracks
    expected_tracks = @db.sqlite.execute('SELECT persistent_id FROM user_playlist_entry').map(&:first)
    expect(expected_tracks).to eq(@tracks)
    expect(@db.get_current_track_and_offset('USERID').offset_in_milliseconds).to eq(333)
    expect(@db.is_next_track_enqueued?('USERID')).to be(false)
  end

  it 'should request the first playlist tracks from the library and store the offset' do
    playlist = Database::UserPlaylist.new('id', 'name')
    expect(Library).to receive(:get_playlist_matching_term).with('good').and_return(playlist)
    expect(Library).to receive(:get_first_five_tracks_from_playlist).with(playlist).and_return(@tracks)
    expect(EnqueueFullPlaylistJob).to receive(:perform_async).with('USERID', playlist, 3)
    expect_enqueue_track0
    @custom_intents.on_play(Request.new(nil, 'USERID', nil, { 'playlist' => 'good' }, nil, nil), @builder)
    expect_enqueued_tracks
  end

  it 'should request the first tracks from the library and store the offset' do
    playlist = Database::UserPlaylist.new('id', 'name')
    expect(Library).to receive(:get_library_playlist).and_return(playlist)
    expect(Library).to receive(:get_first_five_tracks_from_playlist).and_return(@tracks)
    expect(EnqueueFullPlaylistJob).to receive(:perform_async).with('USERID', playlist, 3)
    expect_enqueue_track0
    @custom_intents.on_play(Request.new(nil, 'USERID', nil, nil, nil, nil), @builder)
    expect_enqueued_tracks
  end

  it 'should enqueue artist tracks' do
    expect(Library).to receive(:get_tracks_for_artist_matching).with('kid cudi').and_return(@tracks)
    expect_enqueue_track0
    @custom_intents.on_play(Request.new(nil, 'USERID', nil, { 'artist' => 'kid cudi' }, nil, nil), @builder)
    expect_enqueued_tracks
  end

  it 'should enqueue album tracks' do
    expect(Library).to receive(:get_tracks_for_album_matching).with('man on the moon').and_return(@tracks)
    expect_enqueue_track0
    @custom_intents.on_play(Request.new(nil, 'USERID', nil, { 'album' => 'man on the moon' }, nil, nil), @builder)
    expect_enqueued_tracks
  end

  it 'should enqueue song tracks' do
    expect(Library).to receive(:get_tracks_for_song_matching).with('soundtrack 2 my life').and_return(@tracks)
    expect_enqueue_track0
    @custom_intents.on_play(Request.new(nil, 'USERID', nil, { 'song' => 'soundtrack 2 my life' }, nil, nil), @builder)
    expect_enqueued_tracks
  end

  it 'should enqueue genre tracks' do
    expect(Library).to receive(:get_tracks_for_genre_matching).with('hip hop').and_return(@tracks)
    expect_enqueue_track0
    @custom_intents.on_play(Request.new(nil, 'USERID', nil, { 'genre' => 'hip hop' }, nil, nil), @builder)
    expect_enqueued_tracks
  end
end
