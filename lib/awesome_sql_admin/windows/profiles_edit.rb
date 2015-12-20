# This class controls the window when making and editing db-profiles.
class AwesomeSqlAdmin::Windows::ProfilesEdit
  attr_accessor :gui
  attr_accessor :window
  attr_accessor :win_dbprofile
  attr_accessor :mode
  attr_accessor :types
  attr_accessor :types_text
  attr_accessor :types_nr
  attr_accessor :edit_data

  # The constructor of WinDBProfilesEdit.
  def initialize(win_dbprofile, mode = "add")
    @gui = Gtk::Builder.new
    @gui.add("#{File.dirname(__FILE__)}/ui/win_dbprofiles_edit.ui")
    @gui.connect_signals { |handler| method(handler) }

    @window = @gui[:window]
    winsetting = GtkSettingsWindow.new(@window, "win_dbprofiles_edit")

    @win_dbprofile = win_dbprofile
    @window.set_transient_for(win_dbprofile.window)
    @mode = mode

    # Typer der kan bruges.
    @types["mysql"] = "MySQL"
    @types["mysqli"] = "MySQLi"
    @types["pgsql"] = "PostgreSQL"
    @types["sqlite"] = "SQLite"
    @types["sqlite3"] = "SQLite3"
    @types["mssql"] = "MS-SQL"
    @types["access"] = "Access"

    @types_text["mysql"] = 0
    @types_text["mysqli"] = 1
    @types_text["pgsql"] = 2
    @types_text["sqlite"] = 3
    @types_text["sqlite3"] = 4
    @types_text["mssql"] = 5
    @types_text["access"] = 6

    @types_nr[0] = "mysql"
    @types_nr[1] = "mysqli"
    @types_nr[2] = "pgsql"
    @types_nr[3] = "sqlite"
    @types_nr[4] = "sqlite3"
    @types_nr[5] = "mssql"
    @types_nr[6] = "access"

    require_once("knjphpframework/functions_combobox.php")
    combobox_init(@gui[:cmbType])
    @types.each do |value|
      @gui[:cmbType].append_text(value)
    end
    @gui[:cmbType].set_active(0)

    if @mode == "edit"
      # NOTE: Remember that the tv_profiles is in multiple mode, so it is possible to open more than one database at a time. This affects the returned array from treeview_getSelection().
      editvalue = treeview_getSelection(@win_dbprofile.tv_profiles)
      @edit_data = get_myDB.selectsingle("profiles", {"nr" => editvalue[0][0]})

      if file_exists(edit_data[location])
        @gui[:fcbLocation].set_filename(edit_data[location])
      end

      @gui[:texIP].set_text(edit_data[location])
      @gui[:texTitle].set_text(edit_data[title])
      @gui[:texUsername].set_text(edit_data[username])
      @gui[:texPassword].set_text(edit_data[password])
      @gui[:texDatabase].set_text(edit_data[database])
      @gui[:texPort].set_text(edit_data[port])
      @gui[:cmbType].set_active(types_text[edit_data[type]])
    end

    @window.show_all
    validateType
  end

  # Hides unrelevant widgets based on the choosen type of database.
  def validateType
    active = @types_nr[glade.get_widget("cmbType").get_active]
    if active == "mysql" || active == "postgresql" || active == "mysqli" || active == "mssql"
      @gui[:texIP].show
      @gui[:texUsername].show
      @gui[:texPassword].show
      @gui[:texPort].show
      @gui[:texDatabase].show

      @gui[:labIP].show
      @gui[:labUsername].show
      @gui[:labPassword].show
      @gui[:labPort].show
      @gui[:labDatabase].show

      @gui[:fcbLocation].hide
      @gui[:labLocation].hide
      @gui[:btnNewFile].hide
    elsif active == "sqlite" || active == "access" || active == "sqlite3"
      @gui[:texIP].hide
      @gui[:texUsername].hide
      @gui[:texPassword].hide
      @gui[:texPort].hide
      @gui[:texDatabase].hide

      @gui[:labIP].hide
      @gui[:labUsername].hide
      @gui[:labPassword].hide
      @gui[:labPort].hide
      @gui[:labDatabase].hide

      @gui[:fcbLocation].show
      @gui[:labLocation].show
      @gui[:btnNewFile].show
    end
  end

  # Saves the database-profile and closes the window.
  def SaveClicked
    nr = @edit_data[nr]
    title = @gui[:texTitle].get_text
    type =    @types_nr[glade.get_widget("cmbType").get_active]
    port =    @gui[:texPort].get_text
    location = @gui[:fcbLocation].get_filename
    ip =     @gui[:texIP].get_text
    username =  @gui[:texUsername].get_text
    password =  @gui[:texPassword].get_text
    db = @gui[:texDatabase].get_text

    if type == "mysql" || type == "mysqli" || type == "postgresql" || type == "mssql"
      location = ip
    end

    if @mode == "edit"
      get_myDB.update("profiles", {
                        "title" => title,
                        "type" => type,
                        "port" => port,
                        "location" => location,
                        "username" => username,
                        "password" => password,
                        "database" => db
                      }, {"nr" => nr})
    elsif @mode == "add"
      get_MyDB.insert("profiles", {
                        "title" => title,
                        "type" => type,
                        "port" => port,
                        "location" => location,
                        "username" => username,
                        "password" => password,
                        "database" => db
                      }
      )
    end

    @win_dbprofile.UpdateCList()
    closeWindow
  end

  # Closes the window.
  def closeWindow
    @window.destroy
    unset(@gui, @window, @win_dbprofile); # Clean memory.
  end

  # Creates a database.new-file (just an empty file actually).
  def on_btnNewFile_clicked
    filename = dialog_saveFile.newDialog
    if filename
      file_put_contents(filename, "")
      @gui[:fcbLocation].set_filename(filename)
    end
  end
end
