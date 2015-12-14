# This class contains the controls for the table-creating window.
class WinTableCreate
  attr_accessor :glade
  attr_accessor :window

  attr_accessor :columns        # The columns of the table from the database.
  attr_accessor :numb_columns    # The total count of columns.
  attr_accessor :columns_numkeys  # The columns with the key as count.

  attr_accessor :labels        # All the GtkLabels for the columns.
  attr_accessor :names        # The GtkEntry's which contains the column-names.
  attr_accessor :maxlengths      # The GtkEntry's which contains the maxlength.
  attr_accessor :types        # The GtkComboBox's which contain the column-type.
  attr_accessor :defaults      # The GtkEntry's which contains the column-defaults.
  attr_accessor :autoincr
  attr_accessor :prim
  attr_accessor :notnull

  # *The constructor of WinTableCreate. */
  def initialize(tablename, mode, numb_columns = 0)
    @glade = new GladeXML("glades/win_table_create.glade")
    @glade.signal_autoconnect_instance(self)

    @window = @glade.get_widget("window")
    winsetting = new GtkSettingsWindow(@window, "win_table_create")

    global win_main
    @window.set_transient_for(win_main.window)

    @dbconn = get_winMain().dbconn
    @tablename = tablename
    @mode = mode

    if mode == "addcolumns"
      columns = @dbconn.getTable(tablename).getColumns()
    elsif mode == "editcolumns"
      columns = @dbconn.getTable(tablename).getColumns()
      numb_columns = count(columns)
    end

    if columns
      foreach(columns AS column)
        @columns[column.data["name"]] = column
        @columns_numkeys[] = column
      end
    end

    @numb_columns = numb_columns
    temp = [)

    table = new GtkTable()
    lab_name = new GtkLabel(_("Name"))
    lab_name.set_alignment(0, 0.5)

    lab_type = new GtkLabel(_("Type"))
    lab_type.set_alignment(0, 0.5)

    lab_maxlength = new GtkLabel(_("Max length"))
    lab_maxlength.set_alignment(0, 0.5)

    lab_default = new GtkLabel(_("Default"))
    lab_default.set_alignment(0, 0.5)

    lab_notnull = new GtkLabel(_("Not null"))
    lab_notnull.set_alignment(0, 0.5)

    lab_autoincr = new GtkLabel(_("Auto inc"))
    lab_autoincr.set_alignment(0, 0.5)

    lab_prim = new GtkLabel(_("Prim key"))
    lab_prim.set_alignment(0, 0.5)

    table.attach(lab_name, 1, 2, 0, 1, Gtk::FILL, Gtk::FILL)
    table.attach(lab_type, 2, 3, 0, 1, Gtk::FILL, Gtk::FILL)
    table.attach(lab_maxlength, 3, 4, 0, 1, Gtk::FILL, Gtk::FILL)
    table.attach(lab_default, 4, 5, 0, 1, Gtk::FILL, Gtk::FILL)
    table.attach(lab_notnull, 5, 6, 0, 1, Gtk::FILL, Gtk::FILL)
    table.attach(lab_autoincr, 6, 7, 0, 1, Gtk::FILL, Gtk::FILL)
    table.attach(lab_prim, 7, 8, 0, 1, Gtk::FILL, Gtk::FILL)

    tcount = 1
    count = 0

    column_types = [
      "decimal",
      "varchar",
      "char",
      "tinyint",
      "mediumint",
      "int",
      "text",
      "numeric",
      "blob",
      "enum",
      "date",
      "datetime"
    )
    sort(column_types)
    foreach(column_types AS key => value)
      types[value] = key
    end

    while(count < self.numb_columns)
      @labels[count] = new GtkLabel(_("Column") . " " . (count + 1))
        @labels[count].set_alignment(0, 0.5)

      @names[count] = new GtkEntry()
        @names[count].set_size_request(90, -1)

      @maxlengths[count] = new GtkEntry()
        @maxlengths[count].set_max_length(8)
        @maxlengths[count].set_size_request(50, -1)

      @types[count] = GtkComboBox::new_text()
      foreach(column_types AS value)
        @types[count].append_text(strtoupper(value))
      end
      @types[count].set_active(0)

      @defaults[count] = new GtkEntry()
      @notnull[count] = new GtkCheckButton()
      @autoincr[count] = new GtkCheckButton()
      @prim[count] = new GtkCheckButton()

      if mode == "editcolumns"
        column = @columns_numkeys[count]
        @names[count].set_text(column.get("name"))
        @defaults[count].set_text(column.get("default"))

        # Access cannot set a maxlength on integers and counters.
        if @dbconn.type == "access"
          if @columns_numkeys[count][type] != "int" && @columns_numkeys[count][type] != "counter"
            @maxlengths[count].set_text(self.columns_numkeys[count]['maxlength'])
          end
        else
          @maxlengths[count].set_text(column.get("maxlength"))
        end

        if @dbconn.type == "access" && column.get("type") == "counter"
          # sets to integer if the type is a Access-counter.
          @types[count].set_active(1)
        else
          @types[count].set_active(types[column.get("type")])
        end

        if column.get("notnull") == "yes"
          @notnull[count].clicked()
        end

        if column.get("primarykey") == "yes" || column.get("type") == "counter"
          @prim[count].clicked()
        end

        if column.get("type") == "counter" || column.get("autoincr") == "yes"
          @autoincr[count].clicked()
        end
      elsif mode == "createtable" || mode == "addcolumns"
        @notnull[count].clicked()
      end

      table.attach(@labels[count], 0, 1, tcount, tcount + 1, Gtk::FILL, Gtk::FILL)
      table.attach(@names[count], 1, 2, tcount, tcount + 1)
      table.attach(@types[count], 2, 3, tcount, tcount + 1, Gtk::FILL, Gtk::FILL)
      table.attach(@maxlengths[count], 3, 4, tcount, tcount + 1)
      table.attach(@defaults[count], 4, 5, tcount, tcount + 1)
      table.attach(@notnull[count], 5, 6, tcount, tcount + 1, Gtk::FILL, Gtk::FILL)
      table.attach(@autoincr[count], 6, 7, tcount, tcount + 1, Gtk::FILL, Gtk::FILL)
      table.attach(@prim[count], 7, 8, tcount, tcount + 1, Gtk::FILL, Gtk::FILL)

      tcount++
      count++
    end

    @glade.get_widget("vbox_columns").pack_start(table, false, false)
    @window.show_all()
    table.show_all()
  end

  # *Closes the window. */
  def CloseWindow
    @window.destroy()
  end

  # *Handels the event when the save-button is clicked. */
  def ButtonOkClicked
    for(count = 0; count < @numb_columns; count++)
      maxlength = @maxlengths[count].get_text()
      name = @names[count].get_text()
      type = @types[count].get_active_text()
      prim = @prim[count].active
      default = @defaults[count].get_text()
      autoincr = @autoincr[count].active
      notnull = @notnull[count].active

      # Checking that the column name isnt the same as an existing column.
      if mode == "addcolumns"
        foreach(@columns AS value)
          if trim(strtolower(name)) == strtolower(value[name])
            msgbox(_("Warning"), _("A column has the same name as an existing column."), "warning")
            return false
          end
        end
      end

      if type == "VARCHAR"
        type = "varchar"
      elsif type == "INTEGER"
        type = "int"
      else
        type = strtolower(type)
      end

      if !prim
        prim = "no"
      else
        prim = "yes"
      end

      if !autoincr
        autoincr = "no"
      else
        autoincr = "yes"
      end

      if !notnull
        notnull = "no"
      else
        notnull = "yes"
      end

      # Recognizable error-handeling.
      if @dbconn.type == "access" && type == "int" && maxlength
        msgbox(_("Warning"), _("Access does not support a maxlength-value on a integer-column.\n\nPlease leave the maxlength-textfield empty on the column: '") . name . "'.", "warning")
        return false
      end

      if maxlength && type != "decimal" && type != "enum" && !is_numeric(maxlength)
        msgbox(_("Warning"), _("You have filled the maxlength-textfield with a non-numeric-value.\n\nPlease change this to an empty- or a numeric value at the column: '") . name . "'.", "warning")
        return false
      end

      if prim == "yes" && type != "int"
        msgbox(_("Warning"), _("The primary key can only be a integer at the column: '") . name . "'.", "warning")
        return false
      end

      if autoincr == "yes" && type != "int"
        msgbox(_("Warning"), _("You cant set autoincrement on a varchar at the column: '") . name . "'.")
        return false
      end
      # End of the recognizable error-handeling.

      newcolumns[] = [
        "name" => name,
        "type" => type,
        "primarykey" => prim,
        "notnull" => notnull,
        "maxlength" => maxlength,
        "default" => default
      )
    end

    try
      if @mode == "addcolumns"
        # Running DBConn-command for adding columns.
        @dbconn.getTable(self.tablename).addColumns(newcolumns)
      elsif @mode == "editcolumns"
        # Running DBConn-command for editing columns.
        count = 0
        foreach(@columns AS key => column)
          newdata = newcolumns[count]
          column.setData(newdata)
          count++
        end
      elsif @mode == "createtable"
        get_winMain().getDBConn().tables().createTable(@tablename, newcolumns)
      end

      # Update main-window and close this window.
      get_winMain().dbpage.TablesUpdate()
      @CloseWindow()
    rescue TralaException eknj_msgbox::error_exc(e)
    end
  end
end
