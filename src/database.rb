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
        hashed_user_id TEXT,
        current_index INTEGER,
        total_entries INTEGER,
        current_offset_in_milliseconds INTEGER,
        next_enqueued BOOLEAN
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
    hashed_user_id = Digest::MD5.hexdigest(user_id)
    rows = @sqlite.execute('SELECT id FROM user_playlist WHERE hashed_user_id=?', hashed_user_id)

    if !rows.empty?
      @sqlite.execute('DELETE FROM user_playlist WHERE hashed_user_id=?', hashed_user_id);
      @sqlite.execute('DELETE FROM user_playlist_entry WHERE user_playlist_id=?', rows[0][0].to_i);
    end

    @sqlite.execute('INSERT INTO user_playlist (hashed_user_id, current_index, total_entries, current_offset_in_milliseconds, next_enqueued) VALUES (?, 0, ?, 0, 0);', hashed_user_id, track_ids.count)
    user_playlist_id = @sqlite.last_insert_row_id

    track_ids.each_with_index do |track_id, index|
      @sqlite.execute('INSERT INTO user_playlist_entry (user_playlist_id, playlist_index, persistent_id) VALUES (?, ?, ?)',
                  user_playlist_id, index, track_id)
    end
  end

  def append_tracks(user_id, track_ids)
    hashed_user_id = Digest::MD5.hexdigest(user_id)
    user_playlist_id = @sqlite.get_first_value('SELECT id FROM user_playlist WHERE hashed_user_id=?', hashed_user_id)
    first_index = @sqlite.get_first_value('SELECT COUNT(*) FROM user_playlist_entry WHERE user_playlist_id=?', user_playlist_id)

    track_ids.each_with_index do |track_id, index|
      @sqlite.execute('INSERT INTO user_playlist_entry (user_playlist_id, playlist_index, persistent_id) VALUES (?, ?, ?)',
                  user_playlist_id, index + first_index, track_id)
    end

    @sqlite.execute('UPDATE user_playlist SET total_entries=? WHERE id=?', first_index + track_ids.count, user_playlist_id)
  end

  def is_valid_user?(user_id)
    hashed_user_id = Digest::MD5.hexdigest(user_id)
    @sqlite.get_first_value('SELECT COUNT(*) FROM user_playlist WHERE hashed_user_id=?', hashed_user_id) != 0
  end

  def is_next_track_enqueued?(user_id)
    hashed_user_id = Digest::MD5.hexdigest(user_id)
    @sqlite.get_first_value('SELECT next_enqueued FROM user_playlist WHERE hashed_user_id=?', hashed_user_id) == 1 ? true : false
  end

  def set_is_next_track_enqueued(user_id, value)
    hashed_user_id = Digest::MD5.hexdigest(user_id)
    @sqlite.get_first_value('UPDATE user_playlist SET next_enqueued=? WHERE hashed_user_id=?', value ? 1 : 0, hashed_user_id)
  end

  def update_offset(user_id, offset_in_milliseconds)
    hashed_user_id = Digest::MD5.hexdigest(user_id)
    @sqlite.execute('UPDATE user_playlist SET current_offset_in_milliseconds=? WHERE hashed_user_id=?', offset_in_milliseconds, hashed_user_id)
  end

  def get_current_track_and_offset(user_id)
    hashed_user_id = Digest::MD5.hexdigest(user_id)
    playlist = get_user_playlist(hashed_user_id)
    TrackIdAndOffset.new(get_track_id_at_index(playlist.id, playlist.current_index), playlist.current_offset_in_milliseconds)
  end

  def get_next_track(user_id)
    hashed_user_id = Digest::MD5.hexdigest(user_id)
    playlist, new_playlist_index = get_playlist_and_next_track_index(hashed_user_id)
    get_track_id_at_index(playlist.id, new_playlist_index)
  end

  def get_next_track_and_update_playlist(user_id)
    hashed_user_id = Digest::MD5.hexdigest(user_id)
    playlist, new_playlist_index = get_playlist_and_next_track_index(hashed_user_id)
    update_current_index_and_get_track(playlist.id, new_playlist_index)
  end

  def get_previous_track_and_update_playlist(user_id)
    hashed_user_id = Digest::MD5.hexdigest(user_id)
    playlist = get_user_playlist(hashed_user_id)
    new_playlist_index = playlist.current_index - 1
    new_playlist_index = playlist.total_entries - 1 if new_playlist_index < 0

    update_current_index_and_get_track(playlist.id, new_playlist_index)
  end

  private

  def get_user_playlist(hashed_user_id)
    rows = @sqlite.execute('SELECT id, current_index, total_entries, current_offset_in_milliseconds FROM user_playlist WHERE hashed_user_id=?', hashed_user_id)
    raise UserIdNotFoundException.new if rows.empty?
    UserPlaylist.new(*rows[0])
  end

  def get_playlist_and_next_track_index(hashed_user_id)
    playlist = get_user_playlist(hashed_user_id)
    new_playlist_index = playlist.current_index + 1
    new_playlist_index = 0 if new_playlist_index >= playlist.total_entries

    [playlist, new_playlist_index]
  end

  def update_current_index_and_get_track(user_playlist_id, new_index)
    @sqlite.execute('UPDATE user_playlist SET current_index=?, current_offset_in_milliseconds=0 WHERE id=?', new_index, user_playlist_id);
    get_track_id_at_index(user_playlist_id, new_index)
  end

  def get_track_id_at_index(user_playlist_id, playlist_index)
    @sqlite.get_first_value('SELECT persistent_id FROM user_playlist_entry WHERE user_playlist_id=? AND playlist_index=?', user_playlist_id, playlist_index);
  end
end
