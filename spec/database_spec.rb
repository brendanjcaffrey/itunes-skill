require 'rspec'
require 'sqlite3'
require_relative '../src/database.rb'

class Database ; def self.set_database_name(name) ; @database_name = name ; end ; attr_reader :db ; end

describe Database do
  before :each do
    name = 'itunes_skill_test.db'
    Database.set_database_name(name)
    File.delete(name) if File.exists?(name)
    Database.create_tables
    @db = Database.new
    @sqlite = @db.db
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

  describe 'get_next_track' do
    it 'should get the next track without advancing' do
      @db.create_or_replace_user_playlist('USERID', ['TRACK0', 'TRACK1', 'TRACK2'])
      expect(@db.get_next_track('USERID')).to eq('TRACK1')
      expect(@db.get_next_track('USERID')).to eq('TRACK1')
    end

    it 'should loop around' do
      @db.create_or_replace_user_playlist('USERID', ['TRACK0', 'TRACK1', 'TRACK2'])
      @sqlite.execute('UPDATE user_playlist SET current_index=2')
      expect(@db.get_next_track('USERID')).to eq('TRACK0')
      expect(@db.get_next_track('USERID')).to eq('TRACK0')
    end
  end

  describe 'advance_user_playlist' do
    it 'should increment and loop' do
      @db.create_or_replace_user_playlist('USERID', ['TRACK0', 'TRACK1', 'TRACK2'])
      expect(@sqlite.get_first_value('SELECT current_index FROM user_playlist')).to eq(0)
      @db.advance_user_playlist('USERID')
      expect(@sqlite.get_first_value('SELECT current_index FROM user_playlist')).to eq(1)
      @db.advance_user_playlist('USERID')
      expect(@sqlite.get_first_value('SELECT current_index FROM user_playlist')).to eq(2)
      @db.advance_user_playlist('USERID')
      expect(@sqlite.get_first_value('SELECT current_index FROM user_playlist')).to eq(0)
    end
  end
end
