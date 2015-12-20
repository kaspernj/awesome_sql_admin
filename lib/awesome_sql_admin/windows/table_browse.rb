# This class controls the window which is able to browse and manipulate with data within a given table.
class AwesomeSqlAdmin::Windows::TableBrowse
  attr_accessor :dbconn, :gui, :window, :tv_rows, :updated, :dbpage, :table

  def initialize(dbpage, table)
    @dbpage = dbpage
    @dbconn = @dbpage.dbconn
    @table = table

    @gui = Gtk::Builder.new
    @gui.add("#{File.dirname(__FILE__)}/ui/win_table_browse.ui")
    @gui.connect_signals { |handler| method(handler) }

    @window = @gui[:window]
    winsetting = GtkSettingsWindow.new(@window, "win_table_browse")

    global win_main
    @window.set_transient_for(win_main.window)

    unless table
      msgbox(_("Error"), _("No table is currently selected."), "warning")
      self.CloseWindow
      return null
    end

    # Read columns.
    @columns = @dbconn.getTable(self.table).getColumns
    unless columns
      msgbox(_("Error"), _("No columns found for this table."), "warning")
      self.CloseWindow
      return null
    end

    # Add columns to the treeview.
    @columns.each do |column|
      tvcolumns[] = column.get("name")
    end
    @tv_rows = @gui[:tvRows]
    treeview_addColumn(@tv_rows, tvcolumns)

    self.UpdateClist
    @window.show_all
  end

  # *Deletes all rows in the table (not a truncate, and therefore does not reset any auto-increment-values). */
  def DelAllClicked
    if msgbox(_("Question"), _("Do you want to delete all the rows in the table: '") + @table + "'?", "yesno") == "yes"
      @dbconn.delete(table)
      self.UpdateClist
      @updated = true
    end
  end

  # *Asks and then truncates the table. */
  def EmptyClicked
    if msgbox(_("Question"), sprintf(_("Do you want to truncate the table: \"%s\"?"), @table), "yesno") == "yes"
      unless dbconn.TruncateTable(table)
        msgbox(_("Warning"), sprintf(_("Could not truncate the table.\n\n%s"), query_error), "warning")
      end

      self.UpdateClist
      @updated = true
    end
  end

  # *Deletes the selected row from the table. */
  def DeleteSelectedClicked
    # Get required data.
    selected = treeview_getSelection(@tv_rows)

    # Tjeck for possible failure and interrupt.
    unless selected
      msgbox(_("Warning"), _("You have not selected any row."), "warning")
      return false
    end

    # Think about what to tell the database.
    columns = @dbconn.getTable(table).getColumns
    count = 0
    @columns.each do |value|
      columns_del[value.get("name")] = selected[count]
      count += 1
    end

    begin
      @dbconn.delete(table, columns_del)
    rescue => e
      msgbox(_("Error"), sprintf(_("The selected row could not be deleted: %s"), e.getMessage), "warning")
    end

    # Update clist and mark as updated for closing procedures.
    selection = @tv_rows.get_selection
    iter = selection.get_selected
    model.remove(iter)
    @updated = true
  end

  # *Reloads the rows-treeview. */
  def UpdateClist
    begin
      status_countt = @dbconn.getTable(table).countRows
      status_count = 0

      require_once("knjphpframework/win_status.php")
      win_status = WinStatus.new("window_parent" => @window)
      win_status.SetStatus(0, sprintf(_("Reading table rows %s."), "(" + status_count + "/" + status_countt + ")"), true)

      @tv_rows.get_model.clear
      f_gc = @dbconn.select(table)
      while (d_gc = f_gc.fetch)
        array = []
        status_count += 1
        count = 0
        @columns.each do |column|
          array[] = string_oneline(d_gc[column.get("name")])
          count += 1
        end

        @tv_rows.get_model.append(array); # Insert into the clist.
        win_status.SetStatus(status_count / status_countt, sprintf(_("Reading table rows %s."), "(" + status_count + "/" + status_countt + ")"))
      end
    rescue => e
      msgbox(_("Warning"), sprintf(_("An error occurred while trying to reload the rows-treeview: %s"), e.getMessage), "warning")
    end

    win_status.CloseWindow() if win_status
  end

  # *Handels the event, when the insert-row-button is clicked. It opens the insert-row-window. */
  def InsertIntoClicked
    require_once("gui/win_table_browse_insert.php")
    win_table_browse_insert = WinTableBrowseInsert.new(self)
  end

  # *Closes and destroys the window. */
  def CloseWindow
    @dbpage.TablesUpdate() if @updated == true

    @window.destroy
    unset(@gui, @window, @dbconn, @dbpage, @updated, @table, @tv_rows)
  end

  def on_btnSearch_clicked
    require_once("gui/win_table_browse_search.php")
    win_table_browse_search = WinTableBrowseSearch.new(self)
  end
end
