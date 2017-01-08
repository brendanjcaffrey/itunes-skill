require 'rspec'
require 'sqlite3'
require_relative '../src/custom_intents.rb'
require_relative '../src/library.rb'

describe CustomIntents do
  before :each do
    Database.create_test_database
    @db = Database.new
    @custom_intents = CustomIntents.new(@db)
    @builder = instance_double('ResponseBuilder')
    @user_id_request = Request.new(nil, 'USERID', nil, nil, nil)
  end

  it 'should request tracks from the library and store the offset' do
    tracks = ['TRACK0', 'TRACK1', 'TRACK2']
    expect(Library).to receive(:get_tracks_from_playlist_matching).and_return(tracks)
    expect(Library).to receive(:get_start_milliseconds_for_track_id).with(/TRACK\d/).and_return(333)
    expect(@builder).to receive(:add_play_directive).with('USERID', /TRACK\d/, 333)
    expect(@builder).to receive(:add_plain_text_speech).with('OK')
    @custom_intents.on_play(@user_id_request, @builder)

    sorted_tracks = @db.sqlite.execute('SELECT persistent_id FROM user_playlist_entry').map(&:first).sort
    expect(sorted_tracks).to eq(tracks)
    expect(@db.get_current_track_and_offset('USERID').offset_in_milliseconds).to eq(333)
    expect(@db.is_next_track_enqueued?('USERID')).to be(false)
  end
end
