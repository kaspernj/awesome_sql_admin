require "baza"
require "string-cases"

class AwesomeSqlAdmin
  path = "#{File.dirname(__FILE__)}/awesome_sql_admin"

  autoload :Windows, "#{path}/windows"

  def initialize(_args = {})
    initialize_database

    AwesomeSqlAdmin::Windows::Profiles.new(awesome_sql_admin: self)
  end

private

  def initialize_database
    @config_path = "#{ENV.fetch("HOME")}/.awesome_sql_admin"
    Dir.mkdir(@config_path) unless File.exist?(@config_path)

    @database_path = "#{@config_path}/database.sqlite3"
    @db = Baza::Db.new(type: :sqlite3, path: @database_path)
  end
end
