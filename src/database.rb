class UserIdNotFoundException < Exception ; end

class Database
  class << self ; attr_reader :database_name ; end
  @database_name = 'itunes_skill.db'
  UserPlaylist = Struct.new(:id, :current_index, :total_entries, :current_offset_in_milliseconds)
  TrackIdAndOffset = Struct.new(:track_id, :offset_in_milliseconds)

  def self.create_tables
    return if File.exists?(Database.database_name)

    db = SQLite3::Database.new(Database.database_name)
    db.execute <<-SQL
      CREATE TABLE user_playlist (
        id INTEGER PRIMARY KEY,
        user_id TEXT,
        current_index INTEGER,
        total_entries INTEGER,
        current_offset_in_milliseconds INTEGER
      );
    SQL
    db.execute <<-SQL
      CREATE TABLE user_playlist_entry (
        user_playlist_id INTEGER,
        playlist_index INTEGER,
        persistent_id TEXT
      );
    SQL
  end

  def initialize
    @sqlite = SQLite3::Database.new(Database.database_name)
  end

  def create_or_replace_user_playlist(user_id, track_ids)
    rows = @sqlite.execute('SELECT id FROM user_playlist WHERE user_id=?', user_id)

    if !rows.empty?
      @sqlite.execute('DELETE FROM user_playlist WHERE user_id=?', user_id);
      @sqlite.execute('DELETE FROM user_playlist_entry WHERE user_playlist_id=?', rows[0][0].to_i);
    end

    @sqlite.execute('INSERT INTO user_playlist (user_id, current_index, total_entries, current_offset_in_milliseconds) VALUES (?, 0, ?, 0);', user_id, track_ids.count)
    user_playlist_id = @sqlite.last_insert_row_id

    track_ids.each_with_index do |track_id, index|
      @sqlite.execute('INSERT INTO user_playlist_entry (user_playlist_id, playlist_index, persistent_id) VALUES (?, ?, ?)',
                  user_playlist_id, index, track_id)
    end
  end

  def is_valid_user?(user_id)
    @sqlite.get_first_value('SELECT COUNT(*) FROM user_playlist WHERE user_id=?', user_id) != 0
  end

  def update_offset(user_id, offset_in_milliseconds)
    @sqlite.execute('UPDATE user_playlist SET current_offset_in_milliseconds=? WHERE user_id=?', offset_in_milliseconds, user_id)
  end

  def get_current_track_and_offset(user_id)
    playlist = get_user_playlist(user_id)
    TrackIdAndOffset.new(get_track_id_at_index(playlist.id, playlist.current_index), playlist.current_offset_in_milliseconds)
  end

  def get_next_track_and_update_playlist(user_id)
    playlist = get_user_playlist(user_id)
    new_playlist_index = playlist.current_index + 1
    new_playlist_index = 0 if new_playlist_index >= playlist.total_entries

    update_current_index_and_get_track(playlist.id, new_playlist_index)
  end

  def get_previous_track_and_update_playlist(user_id)
    playlist = get_user_playlist(user_id)
    new_playlist_index = playlist.current_index - 1
    new_playlist_index = playlist.total_entries - 1 if new_playlist_index < 0

    update_current_index_and_get_track(playlist.id, new_playlist_index)
  end

  private

  def get_user_playlist(user_id)
    rows = @sqlite.execute('SELECT id, current_index, total_entries, current_offset_in_milliseconds FROM user_playlist WHERE user_id=?', user_id)
    raise UserIdNotFoundException.new if rows.empty?
    UserPlaylist.new(*rows[0])
  end

  def update_current_index_and_get_track(user_playlist_id, new_index)
    @sqlite.execute('UPDATE user_playlist SET current_index=?, current_offset_in_milliseconds=0 WHERE id=?', new_index, user_playlist_id);
    get_track_id_at_index(user_playlist_id, new_index)
  end

  def get_track_id_at_index(user_playlist_id, playlist_index)
    @sqlite.get_first_value('SELECT persistent_id FROM user_playlist_entry WHERE user_playlist_id=? AND playlist_index=?', user_playlist_id, playlist_index);
  end
end
