# This class controls the main window.
class AwesomeSqlAdmin::Windows::Main
  attr_accessor :gui, :window, :nb_dbs, :dbs_open_count, :dbpage, :dbconn

  # The constructor. This spawns the GladeXML()-object and sets some variables.
  def initialize
    @gui = Gtk::Builder.new
    @gui.add("#{File.dirname(__FILE__)}/ui/main.ui")
    @gui.connect_signals { |handler| method(handler) }

    @window = @gui[:window]
    winsetting = GtkSettingsWindow.new(@window, "win_main")

    @nb_dbs = @gui[:nbDbs]
    @nb_dbs.connect_after("switch-page", [self, "ChangeActiveDB"])

    @window.show_all
  end

  # Return a DBPage()-object from the ID.
  def getDBPage(id)
    @dbs_open[id]
  end

  def SpawnNewDB(title, newdbconn)
    # Spawn a page.new on the main GtkNotebook().
    require_once("gui/class_DBPage.php")
    dbpage = DBPage.new(newdbconn, title, @dbs_open_count)
    @dbs_open[dbs_open_count] = dbpage

    # Used for dragging for identifying which dbpage the dragged element belong to.
    dbpage.tv_tables.other["dbpage_id"] = @dbs_open_count

    # removes the default page, if it is shown.
    unless nb_dbs.default_page_removed
      @nb_dbs.default_page_removed = true
      @nb_dbs.remove_page(0)
    end

    # Require the Notebook_Page()-class.
    require_once("gui/class_Notebook_Page.php")
    nb_page = WinMain_Notebook_Page.new(title, dbpage, self)

    pageid = nb_dbs.append_page(
      dbpage,
      nb_page
    )

    nb_page.dbpage_id = @dbs_open_count
    dbpage.dbpage_id = @dbs_open_count

    # refresh notebook. sets focus on the page.new.
    @nb_dbs.show_all
    @nb_dbs.set_current_page(pageid)

    @dbs_open_count += 1
  end

  # Sets the comfort-variables, when a page.new has been selected.
  def ChangeActiveDB
    @dbpage = @nb_dbs.get_nth_page(nb_dbs.get_current_page)

    # Then we set the main-variables to refelect current page.
    @tv_tables = @dbpage.get_TVTables
    @tv_columns = @dbpage.get_TVColumns
    @tv_indexes = @dbpage.get_TVIndexes
    @dbconn = @dbpage.get_DBConn
  end

  # Open a database.new-profile.
  def OpenDatabaseClicked
    require_once("gui/win_dbprofiles.php")
    win_dbprofiles = WinDBProfiles.new(self)
  end

  # Close the current database-profile.
  def CloseDatabaseClicked
    unless getDBConn
      msgbox(_("Warning"), _("There is no database-connection open at this time."), "warning")
      return null
    end

    @dbpage.destroy
  end

  # Truncates all tabels on all databases.
  def TruncateAllClicked
    unless getDBConn.conn
      msgbox(_("Warning"), _("You need to open a database, before you can truncate its databases"), "warning")
      return null
    end

    if msgbox(_("Question"), _("Do you really want to truncate all databases on the current connection?"), "yesno") != "yes"
      return null
    end

    begin
      dbs = getDBConn.GetDBs()

      dbs.each do |value|
        getDBConn.ChooseDB(value)
        tables = getDBConn.GetTables(value)

        tables.each do |table|
          getDBConn.TruncateTable(table["name"])
        end
      end
    rescue => e
      msgbox(_("Warning"), sprintf(_("An error occurred:\n\n%s"), e.getMessage), "warning")
    end

    @dbpage.TablesUpdate()
  end

  # Select another database than the default one in the database, if the current type if MySQL, PostgreSQL or whatever.
  def SelectOtherDbClicked(knjdb = null, args = null)
    knjdb = @dbpage.dbconn if get_class(knjdb) != "knjdb"

    args = null unless is_[args]

    begin
      require_once("gui/win_databases.php")
      win_dbs = WinDatabases.new(knjdb, args)
    rescue => e
      msgbox(_("Warning"), e.getMessage, "warning")
    end
  end

  # Add a index to the currently selected table and column.
  def IndexAddClicked
    unless getDBConn
      msgbox(_("Warning"), _("Please open a database before trying to add a index."), "warning")
      return null
    end

    table = getTable
    table_ob = @dbconn.getTable(table[0])
    unless table
      msgbox(_("Warning"), _("Please select a table and try again."), "warning")
      return null
    end

    column = treeview_getSelection(@tv_columns)
    column_ob = table_ob.getColumn(column[0])

    unless column_ob
      msgbox(_("Warning"), _("Please select a column to create a index of."), "warning")
      return null
    end

    table_ob.addIndex([column_ob])

    @dbpage.TablesClicked()
    msgbox(_("Information"), _("The index was created with a success."), "info")
  rescue => e
    msgbox(_("Warning"), sprintf(_("An error occurred:\n\n%s"), e.getMessage), "warning")
  end

  # Drop the selected index.
  def IndexDropClicked
    begin
      unless getDBConn
        msgbox(_("Warning"), _("Please open a database before trying to drop a index."), "warning")
        return null
      end

      index = treeview_getSelection(@tv_indexes)
      table = getTable(true)

      unless index
        msgbox(_("Warning"), _("Please select a index to drop and try again."), "warning")
        return null
      end
      index_ob = table.getIndexByName(index[0])

      table.removeIndex(index_ob)
    rescue => e
      knj_msgbox.error_exc(e)
    end

    @dbpage.TablesClicked()
  end

  def RunSQLClicked
    unless getDBConn.conn
      msgbox(_("Warning"), _("You must open a database, before you can execute a SQL-script."), "warning")
      return null
    end

    require_once("gui/win_runsql.php")
    win_runsql = WinRunSQL.new(@dbpage)
  end

  # Backup the current database.
  def BackupDBClicked
    unless getDBConn
      msgbox(_("Warning"), _("You must open a database, before you can do a backup."), "warning")
      return null
    end

    require_once("gui/win_backup.php")
    win_backup = WinBackup.new(self)
  end

  def getTable(ob = false)
    @dbpage.getTable(ob)
  end

  def getDB
    @dbpage.getDB
  end

  # Rename the selected table.
  def TableRenameClicked
    unless getDBConn
      msgbox(_("Warning"), _("Please open a database before trying to rename a table."), "warning")
      return false
    end

    # Getting the marked table and run some possible error-handeling.
    tables = treeview_getSelection(@tv_tables)
    if count(tables) <= 0
      msgbox(_("Warning"), _("Please select the table, that you would like to rename."), "warning")
      return false
    end

    tables.each do |table|
      # Getting the table.new-name from the user.
      tablename = knj_input(_("New table name"), _("Please enter the table.new-name:"), table[0])
      break if tablename == "cancel"

      # If he has enteret the same name.
      if strtolower(tablename) == strtolower(table[0])
        msgbox(_("Warning"), _("The entered name was the same as the current table-name."), "warning")
        break
      end

      # Checking if the table.new-name if valid.
      unless preg_match("/^[a-zA-Z][a-zA-Z0-9_]+/", tablename, match)
        msgbox(_("Warning"), _("The enteret name was not a valid table-name."), "warning")
        break
      end

      # Renaming table and refreshing treeviews.
      begin
        getDBConn.getTable(table[0]).rename(tablename)
      rescue => e
        knj_msgbox.error_exc(e)
      end
    end

    @dbpage.TablesUpdate()
  end

  # Edit the selected table.
  def TableEditClicked
    unless getDBConn
      msgbox(_("Warning"), _("Please open a database before trying to edit a table."), "warning")
      return null
    end

    table = getTable
    unless table
      msgbox(_("Warning"), _("You have to select a table to edit."), "warning")
      return null
    end

    # require and show the window-class.
    require_once("gui/win_table_create.php")
    win_table_create = WinTableCreate.new(table[0], "editcolumns")
  end

  # Truncate the selecting table, leaving it empty.
  def TableTruncate
    begin
      unless getDBConn
        raise _("Please open a database before trying to truncate it.")
      end

      tables = treeview_getSelection(@tv_tables)
      raise _("You have to select a table to truncate.") if count(tables) <= 0

      # Confirm and truncate.
      tables.each do |table|
        table_ob = @dbconn.getTable(table[0])

        if msgbox(_("Question"), sprintf(_("Do you want to truncate the table: %s?"), table[0]), "yesno") == "yes"
          table_ob.truncate
        end
      end
    rescue => e
      knj_msgbox.error_exc(e)
    end

    @dbpage.TablesUpdate()
  end

  # Update the vars, which make it easier to work with the current selected database-profile.
  def updateCurrentVars
    @tv_tables = @dbpage.get_TVTables
    @tv_columns = @dbpage.get_TVColumns
    @tv_indexes = @dbpage.get_TVIndexes
  end

  # Add columns.new to the selected table.
  def ColumnAddClicked
    unless getDBConn
      msgbox(_("Warning"), _("Please open a database before trying to add a column."), "warning")
      return null
    end

    table = getTable
    unless table
      msgbox(_("Warning"), _("You have to select a table to add columns to."), "warning")
      return null
    end

    input = knj_input(_("Number of columns"), _("Write the number of columns, you would like to add to the table:"))

    if input === false
      return null
    elsif !is_numeric(input)
      msgbox(_("Warning"), _("Please write numbers only. Try again."), "warning")
      return null
    end

    # require and show the window-class.
    require_once("gui/win_table_create.php")
    win_column_add = WinTableCreate.new(table[0], "addcolumns", input)
  end

  # Remove the selected column from the table.
  def ColumnRemoveClicked
    begin
      unless getDBConn
        msgbox(_("Warning"), _("Please open a database before trying to remove a column."), "warning")
        return false
      end

      column = treeview_getSelection(@tv_columns)
      table = getTable
      table_ob = @dbconn.getTable(table[0])
      column_ob = table_ob.getColumn(column[0])

      unless column
        msgbox(_("Warning"), _("You have not selected a column."), "warning")
        return false
      end

      if msgbox(_("Question"), sprintf(_("Do you want to remove the selected column: %s?"), column[0]), "yesno") == "yes"
        table_ob.removeColumn(column_ob)
      end
    rescue => e
      knj_msgbox.error_exc(e)
    end

    @dbpage.TablesClicked()
  end

  # Create database.new (if the type is MySQL, PostgreSQL or whatever).
  def CreateNewDatabaseClicked
    unless getDBConn
      msgbox(_("Warning"), _("Please open a database-profile first."), "warning")
      return false
    end

    type = getDBConn.getType
    if type != "mysql" && type != "pgsql"
      msgbox(_("Warning"), sprintf(_("You cant create databases.new of af the current dbtype: %s."), type), "warning")
      return false
    end

    name = knj_input(_("New database name"), _("Please enter the name of the database.new-type:"))
    return false if name == false

    # Create and choose the database.new.
    begin
      getDBConn.dbs.createDB("name" => name)
      db = getDBConn.dbs.getDB(name)
      getDBConn.dbs.chooseDB(db)
      dbpage.tablesUpdate
    rescue => e
      msgbox(_("Warning"), e.getMessage, "warning")
      return false
    end
  end

  def dbOptimize
    db = getDBConn.dbs.getCurrentDB
    db.optimize
    msgbox(_("Information"), _("The database was optimized."), "info")
  rescue => e
    msgbox(_("Warning"), e.getMessage, "warning")
  end

  # Create a table.new in the database.
  def TableCreateClicked
    unless getDBConn.conn
      msgbox(_("Warning"), _("Currently there is no active database."), "warning")
      return null
    end

    tablename = knj_input(_("Name"), _("Please enter the table name:"))
    return null if tablename === false

    unless preg_match("/^[a-zA-Z][a-zA-Z0-9_]+/", tablename, match)
      msgbox(_("Warning"), _("The name you chooce is not a valid table-name."), "warning")
      return null
    end

    columns_count = knj_input(_("Columns"), _("Please enter the number of columns you want:"))
    return null if columns_count === false

    require_once("gui/win_table_create.php")
    win_table_create = WinTableCreate.new(tablename, "createtable", columns_count)
  end

  # Browse the table.
  def TableBrowseClicked
    unless tv_tables
      msgbox(_("Warning"), _("Please open a database-profile first."), "warning")
      return null
    end

    table = getTable
    require_once("gui/win_table_browse.php")
    win_table_browse = WinTableBrowse.new(@dbpage, table[0])
  end

  # Drop the selected table.
  def TableDropClicked
    unless tv_tables
      msgbox(_("Warning"), _("Please open a database-profile first."), "warning")
      return false
    end

    tables = treeview_getSelection(@tv_tables)
    if count(tables) <= 0
      msgbox(_("Warning"), _("You have not selected a table to drop."), "warning")
      return false
    end

    tables.each do |table|
      if msgbox(_("Question"), sprintf(_("Are you sure you want to drop the table: %s?"), table[0]), "yesno") == "yes"
        getDBConn.getTable(table[0]).drop
      end
    end

    @dbpage.TablesUpdate()
  end

  def tableOptimize
    table = getTable(true)

    unless table
      msgbox(_("Warning"), _("Please choose a table."), "warning")
      return null
    end

    table.optimize
    msgbox(_("Information"), _("The table was optimized."), "info")
  end

  # Handels the event when the window is closed. Stops the main-loop and terminating the application.
  def CloseWindow
    @window.hide
    Gtk.main_quit
  end
end
