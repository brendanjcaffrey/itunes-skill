class UserIdNotFoundException < Exception ; end

class Database
  class << self ; attr_reader :database_name ; end
  @database_name = 'itunes_skill.db'

  def self.create_tables
    return if File.exists?(Database.database_name)

    db = SQLite3::Database.new(Database.database_name)
    db.execute <<-SQL
      CREATE TABLE user_playlist (
        id INTEGER PRIMARY KEY,
        user_id TEXT,
        current_index INTEGER,
        total_entries INTEGER
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
    @db = SQLite3::Database.new(Database.database_name)
  end

  def create_or_replace_user_playlist(user_id, track_ids)
    rows = @db.execute('SELECT id FROM user_playlist WHERE user_id=?', user_id)

    if !rows.empty?
      @db.execute('DELETE FROM user_playlist WHERE user_id=?', user_id);
      @db.execute('DELETE FROM user_playlist_entry WHERE user_playlist_id=?', rows[0][0].to_i);
    end

    @db.execute('INSERT INTO user_playlist (user_id, current_index, total_entries) VALUES (?, 0, ?);', user_id, track_ids.count)
    user_playlist_id = @db.last_insert_row_id

    track_ids.each_with_index do |track_id, index|
      @db.execute('INSERT INTO user_playlist_entry (user_playlist_id, playlist_index, persistent_id) VALUES (?, ?, ?)',
                  user_playlist_id, index, track_id)
    end
  end

  def is_valid_user?(user_id)
    @db.get_first_value('SELECT COUNT(*) FROM user_playlist WHERE user_id=?', user_id) != 0
  end

  def get_current_track(user_id)
    user_playlist_id, current_index, _ = get_playlist_info(user_id)
    get_track_id_at_index(user_playlist_id, current_index)
  end

  def get_next_track(user_id)
    get_track_id_at_index(*get_playlist_id_and_next_index(user_id))
  end

  def get_previous_track(user_id)
    get_track_id_at_index(*get_playlist_id_and_previous_index(user_id))
  end

  def increment_playlist_index(user_id)
    update_playlist_index(*get_playlist_id_and_next_index(user_id))
  end

  def decrement_playlist_index(user_id)
    update_playlist_index(*get_playlist_id_and_previous_index(user_id))
  end

  private

  def get_playlist_info(user_id)
    rows = @db.execute('SELECT id, current_index, total_entries FROM user_playlist WHERE user_id=?', user_id)
    raise UserIdNotFoundException.new if rows.empty?

    rows[0]
  end

  def get_playlist_id_and_next_index(user_id)
    user_playlist_id, current_index, total = get_playlist_info(user_id)
    new_playlist_index = current_index + 1
    new_playlist_index = 0 if new_playlist_index >= total

    [user_playlist_id, new_playlist_index]
  end

  def get_playlist_id_and_previous_index(user_id)
    user_playlist_id, current_index, total = get_playlist_info(user_id)
    new_playlist_index = current_index - 1
    new_playlist_index = total - 1 if new_playlist_index < 0

    [user_playlist_id, new_playlist_index]
  end

  def update_playlist_index(user_playlist_id, new_playlist_index)
    @db.get_first_value('UPDATE user_playlist SET current_index=? WHERE id=?', new_playlist_index, user_playlist_id);
  end

  def get_track_id_at_index(user_playlist_id, playlist_index)
    @db.get_first_value('SELECT persistent_id FROM user_playlist_entry WHERE user_playlist_id=? AND playlist_index=?', user_playlist_id, playlist_index);
  end
end
