# This class contains the window when showing the different kind of db-profiles.
class AwesomeSqlAdmin::Windows::Profiles
  attr_accessor :gui, :window, :win_main, :tv_profiles

  # The constructor.
  def initialize(args)
    @awesome_sql_admin = args.fetch(:awesome_sql_admin)
    @db = @awesome_sql_admin.db

    @gui = Gtk::Builder.new
    @gui.add("#{File.dirname(__FILE__)}/ui/profiles.ui")
    @gui.connect_signals { |handler| method(handler) }

    @window = @gui[:window]
    Gtk2_window_settings.new(db: @db, window: @window, name: "win_dbprofiles")

    @win_main = win_main
    @window.set_transient_for(self.win_main.window)

    @tv_profiles = @gui[:tvDBProfiles]
    treeview_addColumn(@tv_profiles, [
      "ID",
      _("Title"),
      _("Type"),
      _("Database")
    ])
    @tv_profiles.get_column(0).set_visible(false)
    @tv_profiles.get_selection.set_mode(Gtk::SELECTION_MULTIPLE)
    settings_profiles = GtkSettingsTreeview.new(@tv_profiles, "dbprofiles_profiles")

    self.UpdateCList
    @window.show_all
  end

  # Handels the event when the enter-key is pressed while the treeview has focus (runs the connect-event).
  def on_tvDBProfiles_key_press_event(_widget, event)
    if event.keyval == Gdk::KEY_Return || event.keyval == Gdk::KEY_KP_Enter
      self.ConnectClicked
    end
  end

  # Updates the treeview with profiles.
  def UpdateCList
    @tv_profiles.get_model.clear
    f_gp = get_MyDB.select("profiles", null, ["orderby" => "title"])
    while (d_gp = f_gp.fetch)
      tv_profiles.get_model.append([
        d_gp["nr"],
        d_gp["title"],
        d_gp["type"],
        d_gp["database"]
      ]
      )
    end
  end

  # Handels the event, when a button-press-event has been initialized on the treeview-object.
  def on_tvDBProfiles_button_press_event(_selection, event)
    self.ConnectClicked if event.type == 5 # Double-clicked.
  end

  # Handels the event when the connect-button is clicked.
  def ConnectClicked
    profiles = treeview_getSelection(@tv_profiles)
    return null unless profiles

    # Show a status-window for opening the database.
    win_status = WinStatus.new(["window_parent" => @window])

    begin
      profiles.each do |value|
        d_gd = get_MyDB.selectsingle("profiles", ["nr" => value[0]])
        unless d_gd
          msgbox(_("Warning"), sprintf(_("Could not find the database-profile for: %s."), value[1]), "warning")
          return null
        end

        win_status.SetStatus(0, sprintf(_("Opening database: %s."), d_gd["title"]), true)
        openProfile(d_gd)
      end

      win_status.CloseWindow()
      self.CloseWindow
    rescue => e
      win_status.CloseWindow()
      knj_msgbox.error_exc(e)
    end
  end

  def openProfile(d_gd)
    # Open the database.
    if d_gd["type"] == "mysql" || d_gd["type"] == "mysqli" || d_gd["type"] == "pgsql" || d_gd["type"] == "mssql"
      load_arr = [
        "type" => d_gd["type"],
        "host" => d_gd["location"],
        "db" => d_gd["database"],
        "user" => d_gd["username"],
        "pass" => d_gd["password"],
        "port" => d_gd["port"]
      ]

      load_db_window = true unless load_arr["db"]
    elsif d_gd["type"] == "sqlite" || d_gd["type"] == "sqlite3"
      # SQLite extension is already loaded, since knjSQLAdmin itself uses this kind of database.
      unless file_exists(d_gd["location"])
        if msgbox(_("Warning"), _("The database could not be found. Do you want to create it?\n\n") . d_gd["location"], "yesno") == "yes"
          fp = fopen(d_gd["location"], "w")

          raise _("The database could not be created.") unless fp

          fclose(fp)
        else
          raise sprintf(_("The file could not be found - aborting.\n\n%s"), d_gd["location"])
        end
      end

      if d_gd["type"] == "sqlite"
        type = "sqlite2"
        dbtype = ""
      elsif d_gd["type"] == "sqlite3"
        type = "pdo"
        dbtype = "sqlite3"
      end

      load_arr = [
        "type" => type,
        "dbtype" => dbtype,
        "path" => d_gd["location"]
      ]
    elsif d_gd["type"] == "access"
      unless file_exists(d_gd["location"])
        if msgbox(_("Warning"), d_gd["location"] . _(" does not exist. Do you want to create an empty Access database?"), "yesno") == "yes"
          copy("Data/Access/empty.mdb", d_gd["location"])
        else
          raise sprintf(_("The file \"%s\" could not be found - aborting.", d_gd["location"]))
        end
      end

      load_arr = [
        "type" => "access",
        "location" => d_gd["location"]
      ]
    else
      raise _("The database-type wasnt given - aborting.")
    end

    newdbconn = knjdb.new
    newdbconn.setOpts(load_arr)

    if load_db_window
      @win_main.SelectOtherDbClicked(newdbconn, ["opennewdbconn" => true, "dbpage_title" => d_gd["title"]])
    else
      spawnid = @win_main.SpawnNewDB(d_gd["title"], newdbconn)
    end
  rescue => e
    msgbox(_("Warning"), e.getMessage, "warning")
  end

  # Handels the event, when the add-button has been clicked.
  def AddClicked
    require_once("win_dbprofiles_edit.php")
    win_dbprofile_edit = WinDBProfilesEdit.new(self, "add")
  end

  # Handels the event, when the edit-button has been clicked.
  def EditClicked
    require_once("win_dbprofiles_edit.php")

    value = treeview_getSelection(@tv_profiles)
    unless value
      msgbox(_("Warning"), _("You have to choose a profile to edit first."), "warning")
      return null
    end

    win_dbprofile_edit = WinDBProfilesEdit.new(self, "edit")
  end

  # Handels the event, when the delete-button has been clicked.
  def DelClicked
    profiles = treeview_getSelection(@tv_profiles)
    unless profiles
      msgbox(_("Warning"), _("You have to choose a profile to delete first."), "warning")
      return null
    end

    profiles.each do |value|
      if msgbox(_("Question"), sprintf(_("Do you want to delete the chossen profile: %s?"), value[1]), "yesno") == "yes"
        get_MyDB.delete("profiles", {"nr" => value[0]})
      end
    end

    self.UpdateCList
  end

  # Closes the window.
  def CloseWindow
    @window.hide
    gtk2_refresh
    @window.destroy
    unset(@window, @gui, @tv_profiles, @win_main); # clean memory.
  end
end
