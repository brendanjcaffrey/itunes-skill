require 'rspec'
require 'sqlite3'
require_relative 'spec_helper.rb'

describe Database do
  before :each do
    Database.create_test_database
    @db = Database.new
    @sqlite = @db.sqlite
  end

  describe 'create_or_replace_user_playlist' do
    it 'should create a new playlist' do
      @db.create_or_replace_user_playlist('USERID', ['TRACK0', 'TRACK1'])

      row = @sqlite.execute('SELECT id, user_id, current_index, total_entries FROM user_playlist')[0]
      playlist_id = row[0]
      expect(row[1]).to eq('USERID')
      expect(row[2]).to eq(0)
      expect(row[3]).to eq(2)

      rows = @sqlite.execute('SELECT playlist_index, persistent_id FROM user_playlist_entry WHERE user_playlist_id=? ORDER BY playlist_index ASC', playlist_id)
      expect(rows[0][0]).to eq(0)
      expect(rows[0][1]).to eq('TRACK0')
      expect(rows[1][0]).to eq(1)
      expect(rows[1][1]).to eq('TRACK1')

      playlists = @sqlite.get_first_value('SELECT COUNT(*) FROM user_playlist')
      expect(playlists).to eq(1)

      entries   = @sqlite.get_first_value('SELECT COUNT(*) FROM user_playlist_entry')
      expect(entries).to eq(2)
    end

    it 'should replace a playlist' do
      @db.create_or_replace_user_playlist('USERID', ['TRACK0', 'TRACK1'])
      @db.create_or_replace_user_playlist('USERID', ['TRACK2', 'TRACK3', 'TRACK4'])

      row = @sqlite.execute('SELECT id, user_id, current_index, total_entries FROM user_playlist')[0]
      playlist_id = row[0]
      expect(row[1]).to eq('USERID')
      expect(row[2]).to eq(0)
      expect(row[3]).to eq(3)

      rows = @sqlite.execute('SELECT playlist_index, persistent_id FROM user_playlist_entry WHERE user_playlist_id=? ORDER BY playlist_index ASC', playlist_id)
      expect(rows[0][0]).to eq(0)
      expect(rows[0][1]).to eq('TRACK2')
      expect(rows[1][0]).to eq(1)
      expect(rows[1][1]).to eq('TRACK3')
      expect(rows[2][0]).to eq(2)
      expect(rows[2][1]).to eq('TRACK4')

      playlists = @sqlite.get_first_value('SELECT COUNT(*) FROM user_playlist')
      expect(playlists).to eq(1)

      entries   = @sqlite.get_first_value('SELECT COUNT(*) FROM user_playlist_entry')
      expect(entries).to eq(3)
    end
  end

  describe 'is_valid_user?' do
    it 'should return true if there\'s a playlist in the database' do
      @db.create_or_replace_user_playlist('USERID', ['TRACK0', 'TRACK1', 'TRACK2'])
      expect(@db.is_valid_user?('USERID')).to be(true)
    end

    it 'should return false if there\'s not a playlist in the database' do
      @db.create_or_replace_user_playlist('USERID', ['TRACK0', 'TRACK1', 'TRACK2'])
      expect(@db.is_valid_user?('INVALID')).to be(false)
    end
  end

  describe 'next_enqueued' do
    it 'should return initialize to 0' do
      @db.create_or_replace_user_playlist('USERID', ['TRACK0', 'TRACK1', 'TRACK2'])
      expect(@sqlite.get_first_value('SELECT next_enqueued FROM user_playlist')).to eq(0)
    end

    it 'should update' do
      @db.create_or_replace_user_playlist('USERID', ['TRACK0', 'TRACK1', 'TRACK2'])
      @db.set_is_next_track_enqueued('USERID', true)
      expect(@sqlite.get_first_value('SELECT next_enqueued FROM user_playlist')).to eq(1)
      @db.set_is_next_track_enqueued('USERID', false)
      expect(@sqlite.get_first_value('SELECT next_enqueued FROM user_playlist')).to eq(0)
    end

    it 'should return as a bool' do
      @db.create_or_replace_user_playlist('USERID', ['TRACK0', 'TRACK1', 'TRACK2'])
      expect(@db.is_next_track_enqueued?('USERID')).to be(false)
      @sqlite.execute('UPDATE user_playlist SET next_enqueued=1')
      expect(@db.is_next_track_enqueued?('USERID')).to be(true)
      @sqlite.execute('UPDATE user_playlist SET next_enqueued=0')
      expect(@db.is_next_track_enqueued?('USERID')).to be(false)
    end
  end

  it 'should update the current offset' do
    @db.create_or_replace_user_playlist('USERID', ['TRACK0', 'TRACK1', 'TRACK2'])
    @db.update_offset('USERID', 500)
    expect(@sqlite.get_first_value('SELECT current_offset_in_milliseconds FROM user_playlist')).to eq(500)
  end

  it 'should get the current track and offset' do
    @db.create_or_replace_user_playlist('USERID', ['TRACK0', 'TRACK1', 'TRACK2'])
    @sqlite.execute('UPDATE user_playlist SET current_offset_in_milliseconds=500')

    track_and_offset = @db.get_current_track_and_offset('USERID')
    expect(track_and_offset.track_id).to eq('TRACK0')
    expect(track_and_offset.offset_in_milliseconds).to eq(500)
  end

  it 'should get the next track without updating the playlist' do
    @db.create_or_replace_user_playlist('USERID', ['TRACK0', 'TRACK1', 'TRACK2'])
    expect(@sqlite.get_first_value('SELECT current_index FROM user_playlist')).to eq(0)
    expect(@db.get_next_track('USERID')).to eq('TRACK1')
    expect(@db.get_next_track('USERID')).to eq('TRACK1')
    expect(@sqlite.get_first_value('SELECT current_index FROM user_playlist')).to eq(0)
  end

  it 'should get the next track and update the current index' do
    @db.create_or_replace_user_playlist('USERID', ['TRACK0', 'TRACK1', 'TRACK2', 'TRACK3'])
    expect(@sqlite.get_first_value('SELECT current_index FROM user_playlist')).to eq(0)
    expect(@db.get_next_track_and_update_playlist('USERID')).to eq('TRACK1')
    expect(@sqlite.get_first_value('SELECT current_index FROM user_playlist')).to eq(1)
    expect(@db.get_next_track_and_update_playlist('USERID')).to eq('TRACK2')
    expect(@sqlite.get_first_value('SELECT current_index FROM user_playlist')).to eq(2)
    expect(@db.get_next_track_and_update_playlist('USERID')).to eq('TRACK3')
    expect(@sqlite.get_first_value('SELECT current_index FROM user_playlist')).to eq(3)
    expect(@db.get_next_track_and_update_playlist('USERID')).to eq('TRACK0')
    expect(@sqlite.get_first_value('SELECT current_index FROM user_playlist')).to eq(0)
  end

  it 'should get the previous track and update the current index' do
    @db.create_or_replace_user_playlist('USERID', ['TRACK0', 'TRACK1', 'TRACK2', 'TRACK3'])
    expect(@sqlite.get_first_value('SELECT current_index FROM user_playlist')).to eq(0)
    expect(@db.get_previous_track_and_update_playlist('USERID')).to eq('TRACK3')
    expect(@sqlite.get_first_value('SELECT current_index FROM user_playlist')).to eq(3)
    expect(@db.get_previous_track_and_update_playlist('USERID')).to eq('TRACK2')
    expect(@sqlite.get_first_value('SELECT current_index FROM user_playlist')).to eq(2)
    expect(@db.get_previous_track_and_update_playlist('USERID')).to eq('TRACK1')
    expect(@sqlite.get_first_value('SELECT current_index FROM user_playlist')).to eq(1)
    expect(@db.get_previous_track_and_update_playlist('USERID')).to eq('TRACK0')
    expect(@sqlite.get_first_value('SELECT current_index FROM user_playlist')).to eq(0)
  end
end
