require "gtk3"
require "gtk2_window_settings"

class AwesomeSqlAdmin::Windows
  def self.const_missing(name)
    file_path = "#{::File.dirname(__FILE__)}/windows/#{::StringCases.camel_to_snake(name)}.rb"

    if ::File.exist?(file_path)
      require file_path
      return const_get(name) if const_defined?(name)
    end

    super
  end
end
