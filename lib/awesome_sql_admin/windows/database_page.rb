# This class contains each of the notebook-pages in the main window for each db-profile which is open.
class AwesomeSqlAdmin::Windows::DatabasePage < GtkVBox
  attr_accessor :dbconn, :gui
  attr_accessor :title          # The title of the DBPage.
  attr_accessor :id            # The ID of the DBPage.
  attr_accessor :tv_tables        # A reference to the tables-treeview.
  attr_accessor :tv_columns        # A reference to the columns-treeview.
  attr_accessor :tv_indexes        # A reference to the indexes-treeview.

  def initialize(dbconn, title, id)
    super

    @dbconn = dbconn
    @title = title
    @id = id

    @gui = Gtk::Builder.new
    @gui.add("#{File.dirname(__FILE__)}/ui/vbox_dbpage.ui")
    @gui.connect_signals { |handler| method(handler) }

    vbox_dbpage = @gui[:vbox_dbpage]
    vbox_dbpage.unparent()

    add(vbox_dbpage)

    @tv_tables = @gui[:tvTables]
    @tv_tables.get_selection().set_mode(Gtk::SELECTION_MULTIPLE)
    treeview_addColumn(@tv_tables, [
        _("Title"),
        _("Columns"),
        _("Rows")
      ]
    )
    @tv_tables.get_selection().connect("changed", [self, "TablesClicked"])
    @tv_tables.drag_source_set(Gdk::BUTTON1_MASK, [["text/plain", 0, 0])) # Enables dragging FROM the clist.
    @tv_tables.connect("drag-data-get", [self, "drag_data_save"]); # Setting the dragged data-object.
    tables_settings = GtkSettingsTreeview.new(@tv_tables, "dbpage_tables")

    @tv_columns = @gui[:tvColumns]
    treeview_addColumn(@tv_columns, [
        _("Title"),
        _("Type"),
        _("Max length"),
        _("Not null"),
        _("Default"),
        _("Primary"),
        _("Auto incr")
      ]
    )
    @tv_columns.get_selection().connect("changed", [get_winMain(), "ColumnsClicked"])
    columns_settings = GtkSettingsTreeview.new(@tv_columns, "dbpage_columns")

    paned_settings = GtkSettingsPaned.new(@gui[:hpanedTablesColumns], "dbpage_tablescolumns")

    @tv_indexes = @gui[:tvIndexes]
    treeview_addColumn(@tv_indexes, [
        _("Title"),
        _("Columns")
      ]
    )
    index_settings = GtkSettingsTreeview.new(@tv_indexes, "dbpage_indexes")

    TablesUpdate() # Fill the treeview with tables.
  end

  def destroy
    @dbconn.close()
    unset(@dbconn, @tv_tables, @tv_columns, @tv_indexes, @gui)
    parent::destroy()
  end

  def drag_data_save(widget, context, data, info, time)
    # FIXME: It gave an error with pure serialize - somehow base64-encode fixed it?
    data.set_text(@id)
  end

  # Returns the DBConn-object for this object.
  def get_DBConn
    return @dbconn
  end

  # Returns the tables-treeview for this object.
  def get_TVTables
    return @tv_tables
  end

  # Returns the columns-treeview for this object.
  def get_TVColumns
    return @tv_columns
  end

  # Returns the indexes-treeview for this object.
  def get_TVIndexes
    return @tv_indexes
  end

  def on_tvTables_button_press_event(selection, event)
    if event.button == 3 # Handels the right-click-event.
      popup = knj_popup.new(
        [
          "browse" => _("Browse"),
          "create_new" => _("Create new"),
          "edit" => _("Edit"),
          "rename" => _("Rename"),
          "truncate" => _("Truncate"),
          "drop" => _("Drop"),
          "refresh" => _("Refresh"),
          "optimize" => _("Optimize")
        ],
        [self, "ClistTablesRightclickMenu"]
      )
    elsif event.type == 5 # doubleclick.
      ClistTablesRightclickMenu("browse")
    end
  end

  def on_tvColumns_button_press_event(selection, event)
    if event.button == 3 # Handels the right-click-event.
      popup = knj_popup.new(
        [
          "add_new" => _("Add columns.new"),
          "add_index" => _("Add index for this column"),
          "drop" => _("Drop column")
        ],
        [self, "ClistColumnsRightclickmenu"]
      )
    end
  end

  def on_tvIndexes_button_press_event(selection, event)
    if event.button == 3 # Handels the right-click-event.
      popup = knj_popup.new(
        {"drop" => _("Drop index")},
        [self, "ClistIndexRightclickmenu"]
      )
    end
  end

  def ClistTablesRightclickMenu(mode)
    if mode == "browse"
      get_winMain().TableBrowseClicked()
    elsif mode == "create_new"
      get_winMain().TableCreateClicked()
    elsif mode == "edit"
      get_winMain().TableEditClicked()
    elsif mode == "rename"
      get_winMain().TableRenameClicked()
    elsif mode == "drop"
      get_winMain().TableDropClicked()
    elsif mode == "truncate"
      get_winMain().TableTruncate()
    elsif mode == "refresh"
      tablesUpdate()
    elsif mode == "optimize"
      get_winMain().tableOptimize()
    end
  end

  def ClistColumnsRightclickmenu(mode)
    if mode == "add_new"
      get_winMain().ColumnAddClicked()
    elsif mode == "drop"
      get_winMain().ColumnRemoveClicked()
    elsif mode == "add_index"
      get_winMain().IndexAddClicked()
    end
  end

  def ClistIndexRightclickmenu(mode)
    if mode == "drop"
      get_winMain().IndexDropClicked()
    end
  end

  # Returns a single table, which is selected (treeview_getSelection() will return multiple).
  def getTable(ob = false)
    tables = treeview_getSelection(@tv_tables)
    table = tables[0]

    if ob
      return @dbconn.getTable(table[0])
    else
      return table
    end
  end

  # Handels the event, when a table.new is selected in the tables-treeview.
  def tablesClicked
    @tv_columns.get_model().clear()
    @tv_indexes.get_model().clear()

    table = getTable()
    if !table
      return null
    end
    table_ob = getTable(true)
    if !table_ob
      return null
    end

    table_ob.getColumns().each do |column|
      self.tv_columns.get_model().append([
          column.get("name"),
          column.get("type"),
          column.get("maxlength"),
          column.get("notnull"),
          column.get("default"),
          column.get("primarykey"),
          column.get("autoincr")
        ]
      )
    end

    table_ob.getIndexes().each do |index|
      self.tv_indexes.get_model().append([
          index.get("name"),
          index.getColText()
        ]
      )
    end

    get_winMain().updateCurrentVars()
  end

  # Reloads the tables in the treeview.
  def tablesUpdate(win_status = null)
    @tv_columns.get_model().clear()
    @tv_tables.get_model().clear()

    if win_status
      win_status.setStatus(0, _("Adding tables to clist (querying)."), true)
    end

    tables = @dbconn.tables().getTables()
    count = 0
    countt = count(tables)
    tables.each do |key, table|
      if win_status
        count++
        win_status.setStatus(count / countt, sprintf(_("Adding tables to list (%s)."), table.get("name")), true)
      end

      count_rows = 0
      count_columns = 0

      count_rows = number_format(table.countRows(), 0, ",", ".")
      count_columns = count(table.getColumns())

      @tv_tables.get_model().append([table.get("name"), count_columns, count_rows])
    end

    if win_status
      win_status.closeWindow()
    end
  end
end
