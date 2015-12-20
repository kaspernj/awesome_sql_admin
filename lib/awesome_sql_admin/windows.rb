require "gtk3"

class AwesomeSqlAdmin::Windows
  path = "#{File.dirname(__FILE__)}/windows"

  def self.const_missing(name)
    file_path = "#{::File.dirname(__FILE__)}/windows/#{::StringCases.camel_to_snake(name)}.rb"

    if ::File.exist?(file_path)
      puts "Require: #{file_path}"
      require file_path
      return const_get(name) if const_defined?(name)
    end

    super
  end
end
