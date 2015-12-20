# This class controls the window, where the user can import SQL-files.
class AwesomeSqlAdmin::Windows::RunSQL
  attr_accessor :gui      # A reference to the GladeXML-object.
  attr_accessor :dbpage      # Reference to the DBPage-object.
  attr_accessor :dbconn      # Reference to the DBConn-object, which is used to write the data to.
  attr_accessor :window      # Reference to the GtkWindow()-object, which is used.
  attr_accessor :cb_type      # A reference to the GtkComboBox where you choose the type of dump.

  # The constructor of WinRunSQL().
  def initialize(dbpage)
    @dbpage = dbpage
    @dbconn = @dbpage.dbconn

    @gui = Gtk::Builder.new.add("#{File.dirname(__FILE__)}/ui/win_runsql.glade")
    @gui.signal_autoconnect_instance(self)

    @cb_type = @gui[:cbType]
    combobox_init(@cb_type)
    @cb_type.get_model().append(["Auto"))
    @cb_type.get_model().append(["One-liners"))
    @cb_type.get_model().append(["phpMyAdmin dump"))
    @cb_type.set_active(0)

    @window = @gui[:window]
    winsetting = GtkSettingsWindow.new(@window, "win_runsql")
    @window.show_all()
  end

  # Closes the window.
  def CloseWindow
    @window.destroy()
  end

  # Imports the SQL-file, which the user have choosen.
  def ReadSQLClicked
    # Get variables.
    filename = @gui[:fcbFile].get_filename()
    type_id = @cb_type.get_active()


    # Error handeling.
    if !file_exists(filename)
      msgbox(_("Warning"), _("The file does not exist."), "warning")
      return false
    end

    if !filename
      msgbox(_("Warning"), _("Please choose a file before executing."), "warning")
      return false
    end

    if !file_exists(filename)
      msgbox(_("Warning"), _("The file you have chosen does not exists."), "warning")
      return false
    end

    if substr(filename, -4, 4) != ".sql" && substr(filename, -7, 7) !== ".sql.gz"
      msgbox(_("Warning"), _("Could not recognize the file extension. It is only possible to parse '.sql' and '.sql.gz'-files."), "warning")
      return false
    end


    # Get type.
    if type_id == 1
      type = "oneliners"
    elsif type_id == 2
      type = "phpmyadmin"
    elsif type_id == 0
      fp = fopen(filename, "r")
      header_read = fread(fp, "1024")
      fclose(fp)

      if strpos(header_read, "-- phpMyAdmin SQL Dump") !== false && strpos(header_read, "-- http:# www.phpmyadmin.net") !== false
        type = "phpmyadmin"
      else
        msgbox(_("Warning"), _("Could not recognize the type of the dump."), "warning")
        return false
      end
    end


    # Open file.
    if substr(filename, -4, 4) == ".sql"
      fp = fopen(filename, "r")
      mode = "plain"

      cont_countt = filesize(filename)
    elsif substr(filename, -7, 7) == ".sql.gz"
      require_once "functions/functions_gz.php"

      fp = gzopen(filename, "r")
      mode = "gz"

      cont_countt = gzfilesize(filename)
    end

    if !fp
      msgbox(_("Warning"), _("Could not open the file."), "warning")
      return null
    end


    # Read file.
    dbconn = get_winMain().dbconn
    dbconn.query("SET NAMES 'utf8'")
    count = 0
    cont_count = 0
    nextcount = 50
    @win_status = WinStatus.new()
    @win_status.SetStatus(0, _("Reading SQL"), true)

    while(!knj_freadline_eof(fp, mode))
      line = trim(knj_freadline(fp, mode))

      if type == "phpmyadmin"
        if !line || substr(line, 0, 2) == "--"
          # nothing.
        elsif substr(line, -1, 1) == ";"
          newcont .= line

          begin
            dbconn.query(newcont)
          rescue => e
            echo newcont
            @win_status.CloseWindow()
            @dbpage.TablesUpdate()
            msgbox(_("Warning"), _("One of the lines failed to be executed. Returned the following error:\n\n") . query_error(), "warning")
            return false
          end

          unset(newcont)
        else
          newcont .= line
        end
      elsif type == "oneliners"
        begin
          dbconn.query(line)
        rescue => e
          echo line
          @win_status.CloseWindow()
          @dbpage.TablesUpdate()
          msgbox(_("Warning"), _("One of the lines failed to be executed. Returned the following error:\n\n") . query_error(), "warning")
          return false
        end
      end

      cont_count += strlen(line)
      count++
      if count >= nextcount
        nextcount = count + 50
        perc = cont_count / cont_countt
        @win_status.SetStatus(perc, _("Reading SQL") . " - " . number_format((cont_count / 1024) / 1024, 2) . " mb - " . round(perc * 100, 0) . "%", true)
      else
        upd = false
      end
    end

    @win_status.CloseWindow()

    if mode == "plain"
      fclose(fp)
    elsif mode == "gz"
      gzclose(fp)
    end

    msgbox(_("Information"), _("The SQL-file has been parsed and executed."), "info")
    @dbpage.TablesUpdate()
    @CloseWindow()
  end
end
