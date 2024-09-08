require_relative '../src/database.rb'

class Database
  attr_reader :sqlite
  def self.create_test_database()
    @database_name = 'itunes_skill_test.db'
    File.delete(@database_name) if File.exist?(@database_name)
    Database.create_tables
  end
end
