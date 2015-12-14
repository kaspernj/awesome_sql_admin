class WinTableBrowseInsert
  attr_accessor :glade
  attr_accessor :dbconn
  attr_accessor :dbpage
  attr_accessor :window
  attr_accessor :win_table_browse
  attr_accessor :table

  attr_accessor :labels
  attr_accessor :entries

  def initialize(win_table_browse)
    @glade = new GladeXML("glades/win_table_browse_insert.glade")
    @glade.signal_autoconnect_instance(self)

    @win_table_browse = win_table_browse
    @dbpage = @win_table_browse.dbpage
    @dbconn = @dbpage.dbconn
    @table = @win_table_browse.table

    @window = @glade.get_widget("window")
    winsetting = new GtkSettingsWindow(@window, "win_table_browse_insert")

    table = new GtkTable()
    @columns = @dbconn.getTable(self.table).getColumns()

    count_rows = 0
    foreach(@columns AS value)
      @labels[count_rows] = new GtkLabel(value.get("name"))
      @labels[count_rows].set_alignment(0, 0.5)

      @entries[count_rows] = new GtkEntry()

      table.attach(@labels[count_rows], 0, 1, count_rows, count_rows + 1, Gtk::FILL, Gtk::FILL)
      table.attach(@entries[count_rows], 1, 2, count_rows, count_rows + 1)

      count_rows++
    end

    @window.show_all()
    @glade.get_widget("vbox_data").pack_start(table, false, false)
    table.show_all()
  end

  def ButtonOkClicked
    try
      count = 0
      foreach(@columns AS key => value)
        insert_val = @entries[count].get_text()

        if insert_val == "" && value.get("notnull") == "yes" && value.get("primarykey") != "yes" && value.get("default") == ""
          # If we dont cancel this operation, it will make some kind of error.
          msgbox(_("Warning"), sprintf(_("The value of the column: \"%s\", may not be NULL."), value.get("name")), "warning")
          return null
        elsif insert_val != ""
          data[value.get("name")] = @entries[count].get_text()
        end

        count++
      end

      @dbconn.insert(self.table, data)
      @win_table_browse.UpdateClist()
      @win_table_browse.updated = true
      @CloseWindow()
    rescue Exception e
      msgbox(_("Warning"), e.getMessage(), "warning")
    end
  end

  def CloseWindow
    @window.destroy()
  end
end
