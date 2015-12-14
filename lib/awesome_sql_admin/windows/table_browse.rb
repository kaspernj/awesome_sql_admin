# This class controls the window which is able to browse and manipulate with data within a given table.
class WinTableBrowse
  attr_accessor :dbconn
  attr_accessor :glade
  public window
  public tv_rows
  public updated
  public dbpage
  public table

  # ** The constructor of WinTableBrowse.
   *
   * @param DBPage dbpage The dbpage which the table should be browsed from.
   * @param string table The table which should be browsed.
  */
  def initialize(dbpage, table)
    @dbpage = dbpage
    @dbconn = @dbpage.dbconn
    @table = table

    @glade = new GladeXML("glades/win_table_browse.glade")
    @glade.signal_autoconnect_instance(self)

    @window = @glade.get_widget("window")
    winsetting = new GtkSettingsWindow(@window, "win_table_browse")

    global win_main
    @window.set_transient_for(win_main.window)

    if !table
      msgbox(_("Error"), _("No table is currently selected."), "warning")
      @CloseWindow()
      return null
    end

    # Read columns.
    @columns = @dbconn.getTable(self.table).getColumns()
    if !self.columns
      msgbox(_("Error"), _("No columns found for this table."), "warning")
      @CloseWindow()
      return null
    end

    # Add columns to the treeview.
    foreach(@columns AS column)
      tvcolumns[] = column.get("name")
    end
    @tv_rows = @glade.get_widget("tvRows")
    treeview_addColumn(@tv_rows, tvcolumns)

    @UpdateClist()
    @window.show_all()
  end

  # *Deletes all rows in the table (not a truncate, and therefore does not reset any auto-increment-values). */
  def DelAllClicked
    if msgbox(_("Question"), _("Do you want to delete all the rows in the table: '") . @table . "'?", "yesno") == "yes"
      @dbconn.delete(self.table)
      @UpdateClist()
      @updated = true
    end
  end

  # *Asks and then truncates the table. */
  def EmptyClicked
    if msgbox(_("Question"), sprintf(_("Do you want to truncate the table: \"%s\"?"), @table), "yesno") == "yes"
      if !self.dbconn.TruncateTable(self.table)
        msgbox(_("Warning"), sprintf(_("Could not truncate the table.\n\n%s"), query_error()), "warning")
      end

      @UpdateClist()
      @updated = true
    end
  end

  # *Deletes the selected row from the table. */
  def DeleteSelectedClicked
    # Get required data.
    selected = treeview_getSelection(@tv_rows)

    # Tjeck for possible failure and interrupt.
    if !selected
      msgbox(_("Warning"), _("You have not selected any row."), "warning")
      return false
    end

    # Think about what to tell the database.
    columns = @dbconn.getTable(self.table).getColumns()
    count = 0
    foreach(@columns AS value)
      columns_del[value.get("name")] = selected[count]
      count++
    end

    try
      @dbconn.delete(self.table, columns_del)
    rescue Exception e
      msgbox(_("Error"), sprintf(_("The selected row could not be deleted: %s"), e.getMessage()), "warning")
    end

    # Update clist and mark as updated for closing procedures.
    selection = @tv_rows.get_selection()
    list(model, iter) = selection.get_selected()
    model.remove(iter)
    @updated = true
  end

  # *Reloads the rows-treeview. */
  def UpdateClist
    try
      status_countt = @dbconn.getTable(self.table).countRows()
      status_count = 0

      require_once("knjphpframework/win_status.php")
      win_status = new WinStatus(["window_parent" => @window))
      win_status.SetStatus(0, sprintf(_("Reading table rows %s."), "(" . status_count . "/" . status_countt . ")"), true)

      @tv_rows.get_model().clear()
      f_gc = @dbconn.select(self.table)
      while(d_gc = f_gc.fetch())
        array = [)
        status_count++
        count = 0
        foreach(@columns AS column)
          array[] = string_oneline(d_gc[column.get("name")])
          count++
        end

        @tv_rows.get_model().append(array); # Insert into the clist.
        win_status.SetStatus(status_count / status_countt, sprintf(_("Reading table rows %s."), "(" . status_count . "/" . status_countt . ")"))
      end
    rescue Exception e
      msgbox(_("Warning"), sprintf(_("An error occurred while trying to reload the rows-treeview: %s"), e.getMessage()), "warning")
    end

    if win_status
      win_status.CloseWindow()
    end
  end

  # *Handels the event, when the insert-row-button is clicked. It opens the insert-row-window. */
  def InsertIntoClicked
    require_once("gui/win_table_browse_insert.php")
    win_table_browse_insert = new WinTableBrowseInsert(self)
  end

  # *Closes and destroys the window. */
  def CloseWindow
    if @updated == true
      @dbpage.TablesUpdate()
    end

    @window.destroy()
    unset(@glade, @window, @dbconn, @dbpage, @updated, @table, @tv_rows)
  end

  def on_btnSearch_clicked
    require_once("gui/win_table_browse_search.php")
    win_table_browse_search = new WinTableBrowseSearch(self)
  end
end
