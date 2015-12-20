# This class contains the controls for the table-creating window.
class AwesomeSqlAdmin::Windows::TableCreate
  attr_accessor :gui, :window, :columns, :numb_columns, :columns_numkeys # The columns with the key as count.

  attr_accessor :labels # All the GtkLabels for the columns.
  attr_accessor :names # The GtkEntry's which contains the column-names.
  attr_accessor :maxlengths # The GtkEntry's which contains the maxlength.
  attr_accessor :types # The GtkComboBox's which contain the column-type.
  attr_accessor :defaults # The GtkEntry's which contains the column-defaults.
  attr_accessor :autoincr
  attr_accessor :prim
  attr_accessor :notnull

  # *The constructor of WinTableCreate. */
  def initialize(tablename, mode, numb_columns = 0)
    @gui = Gtk::Builder.new
    @gui.add("#{File.dirname(__FILE__)}/ui/win_table_create.ui")
    @gui.connect_signals { |handler| method(handler) }

    @window = @gui[:window]
    winsetting = GtkSettingsWindow.new(@window, "win_table_create")

    global win_main
    @window.set_transient_for(win_main.window)

    @dbconn = get_winMain.dbconn
    @tablename = tablename
    @mode = mode

    if mode == "addcolumns"
      columns = @dbconn.getTable(tablename).getColumns
    elsif mode == "editcolumns"
      columns = @dbconn.getTable(tablename).getColumns
      numb_columns = count(columns)
    end

    if columns
      columns.each do |column|
        @columns[column.data["name"]] = column
        @columns_numkeys[] = column
      end
    end

    @numb_columns = numb_columns
    temp = []

    table = GtkTable.new
    lab_name = GtkLabel.new(_("Name"))
    lab_name.set_alignment(0, 0.5)

    lab_type = GtkLabel.new(_("Type"))
    lab_type.set_alignment(0, 0.5)

    lab_maxlength = GtkLabel.new(_("Max length"))
    lab_maxlength.set_alignment(0, 0.5)

    lab_default = GtkLabel.new(_("Default"))
    lab_default.set_alignment(0, 0.5)

    lab_notnull = GtkLabel.new(_("Not null"))
    lab_notnull.set_alignment(0, 0.5)

    lab_autoincr = GtkLabel.new(_("Auto inc"))
    lab_autoincr.set_alignment(0, 0.5)

    lab_prim = GtkLabel.new(_("Prim key"))
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

    column_types = %w(
      decimal
      varchar
      char
      tinyint
      mediumint
      int
      text
      numeric
      blob
      enum
      date
      datetime)
    sort(column_types)
    column_types.each do |key, value|
      types[value] = key
    end

    while count < self.numb_columns
      @labels[count] = GtkLabel.new(_("Column") + " " + (count + 1))
      @labels[count].set_alignment(0, 0.5)

      @names[count] = GtkEntry.new
      @names[count].set_size_request(90, -1)

      @maxlengths[count] = GtkEntry.new
      @maxlengths[count].set_max_length(8)
      @maxlengths[count].set_size_request(50, -1)

      @types[count] = GtkComboBox.new_text
      column_types.each do |value|
        @types[count].append_text(strtoupper(value))
      end
      @types[count].set_active(0)

      @defaults[count] = GtkEntry.new
      @notnull[count] = GtkCheckButton.new
      @autoincr[count] = GtkCheckButton.new
      @prim[count] = GtkCheckButton.new

      if mode == "editcolumns"
        column = @columns_numkeys[count]
        @names[count].set_text(column.get("name"))
        @defaults[count].set_text(column.get("default"))

        # Access cannot set a maxlength on integers and counters.
        if @dbconn.type == "access"
          if @columns_numkeys[count][type] != "int" && @columns_numkeys[count][type] != "counter"
            @maxlengths[count].set_text(columns_numkeys[count]["maxlength"])
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

        @notnull[count].clicked if column.get("notnull") == "yes"

        if column.get("primarykey") == "yes" || column.get("type") == "counter"
          @prim[count].clicked
        end

        if column.get("type") == "counter" || column.get("autoincr") == "yes"
          @autoincr[count].clicked
        end
      elsif mode == "createtable" || mode == "addcolumns"
        @notnull[count].clicked
      end

      table.attach(@labels[count], 0, 1, tcount, tcount + 1, Gtk::FILL, Gtk::FILL)
      table.attach(@names[count], 1, 2, tcount, tcount + 1)
      table.attach(@types[count], 2, 3, tcount, tcount + 1, Gtk::FILL, Gtk::FILL)
      table.attach(@maxlengths[count], 3, 4, tcount, tcount + 1)
      table.attach(@defaults[count], 4, 5, tcount, tcount + 1)
      table.attach(@notnull[count], 5, 6, tcount, tcount + 1, Gtk::FILL, Gtk::FILL)
      table.attach(@autoincr[count], 6, 7, tcount, tcount + 1, Gtk::FILL, Gtk::FILL)
      table.attach(@prim[count], 7, 8, tcount, tcount + 1, Gtk::FILL, Gtk::FILL)

      tcount += 1
      count += 1
    end

    @gui[:vbox_columns].pack_start(table, false, false)
    @window.show_all
    table.show_all
  end

  # *Closes the window. */
  def CloseWindow
    @window.destroy
  end

  # *Handels the event when the save-button is clicked. */
  def ButtonOkClicked
    @numb_columns.times do |count|
      maxlength = @maxlengths[count].get_text
      name = @names[count].get_text
      type = @types[count].get_active_text
      prim = @prim[count].active
      default = @defaults[count].get_text
      autoincr = @autoincr[count].active
      notnull = @notnull[count].active

      # Checking that the column name isnt the same as an existing column.
      if mode == "addcolumns"
        @columns.each do |value|
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
        msgbox(_("Warning"), _("Access does not support a maxlength-value on a integer-column.\n\nPlease leave the maxlength-textfield empty on the column: '") + name + "'.", "warning")
        return false
      end

      if maxlength && type != "decimal" && type != "enum" && !is_numeric(maxlength)
        msgbox(_("Warning"), _("You have filled the maxlength-textfield with a non-numeric-value.\n\nPlease change this to an empty- or a numeric value at the column: '") + name + "'.", "warning")
        return false
      end

      if prim == "yes" && type != "int"
        msgbox(_("Warning"), _("The primary key can only be a integer at the column: '") + name + "'.", "warning")
        return false
      end

      if autoincr == "yes" && type != "int"
        msgbox(_("Warning"), _("You cant set autoincrement on a varchar at the column: '") + name + "'.")
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
      ]
    end

    begin
      if @mode == "addcolumns"
        # Running DBConn-command for adding columns.
        @dbconn.getTable(tablename).addColumns(newcolumns)
      elsif @mode == "editcolumns"
        # Running DBConn-command for editing columns.
        count = 0
        @columns.each do |_key, column|
          newdata = newcolumns[count]
          column.setData(newdata)
          count += 1
        end
      elsif @mode == "createtable"
        get_winMain.getDBConn.tables.createTable(@tablename, newcolumns)
      end

      # Update main-window and close this window.
      get_winMain.dbpage.TablesUpdate()
      self.CloseWindow
    rescue => e
      knj_msgbox.error_exc(e)
    end
  end
end
