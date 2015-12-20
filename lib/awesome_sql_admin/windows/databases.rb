# This class will let the user choose a database.new, if he is working in a multi-database environment (mysql, pgsql or whatever).
class AwesomeSqlAdmin::Windows::Databases
  attr_accessor :window, :gui, :dbconn, :tv_dbs, :args

  # The constructor of WinDatabases.
  def initialize(dbconn, args = null)
    @dbconn = dbconn
    @args = args

    if @dbconn.getType() != "mysql" && @dbconn.getType() != "pgsql"
      raise _("You have to open either a MySQL- or a PostgreSQL database, before choosing this option."))
    end

    @gui = Gtk::Builder.new.add("#{File.dirname(__FILE__)}/ui/databases.glade")
    @gui.signal_autoconnect_instance(self)

    @window = @gui[:window]
    winsetting = GtkSettingsWindow.new(@window, "win_databases")

    @tv_dbs = @gui[:tvDBs]
    treeview_addColumn(@tv_dbs, [
        _("Name")
      ]
    )

    @UpdateDBList()
    @window.show_all()
  end

  # Catches press-events from the databases-treeview (doubleclicks etc).
  def on_tvDBs_button_press_event(selection, event)
    if event.type == 5
      self.ChooseDB # Double-click on the treeview.
    end
  end

  # Chooses the selected database.
  def ChooseDB
    require_once("knjphpframework/win_status.php")
    win_status = WinStatus.new(["window_parent" => @window))
    win_status.setStatus(0, _("Changing database."), true)

    value = treeview_getSelection(@tv_dbs)

    begin
      db = @dbconn.dbs().getDB(value[0])
      state = @dbconn.dbs().chooseDB(db)
      win_status.setStatus(0.5, _("Reloading tables."), true)

      if self.args["opennewdbconn"]
        get_winMain().SpawnNewDB(@args["dbpage_title"], @dbconn)
      else
        get_winMain().dbpage.tablesUpdate()
      end

      win_status.closeWindow()
      @closeWindow()
    rescue => e
      if win_status
        win_status.closeWindow()
      end
      msgbox(_("Warning"), e.getMessage(), "warning")
    end
  end

  # Reloads the list of databases.
  def UpdateDBList
    @tv_dbs.get_model().clear()
    @dbconn.dbs().getDBs().each do |db|
      @tv_dbs.get_model().append([db.getName()))
    end
  end

  # Closes the window.
  def CloseWindow
    @window.destroy()
  end
end
