class WinMain_Notebook_Page < GtkEventBox
  def initialize(title, dbpage)
    super()

    @dbpage = dbpage
    @dbconn = @dbpage.get_DBConn()
    @title = title

    lab_title = new GtkLabel(title)
    @connect("button-press-event", [self, "ItemClicked"))
    @add(lab_title)
    lab_title.show()

    # Enable draggin on the GtkEventBox().
    @drag_source_set(Gdk::BUTTON1_MASK, [["text/plain", 0, 0)), Gdk::ACTION_COPY|Gdk::ACTION_MOVE)
    @connect("drag-data-get", [self, "DragDataSave"))

    # Enable dragging the the GtkNotebook()-items.
    @drag_dest_set(Gtk::DEST_DEFAULT_ALL, [["text/plain", 0, 0)), 0|1|2|3|4|5)
    @connect("drag-data-received", [self, "OnDrop"))
  end

  def DragDataSave(widget, context, data, info, time)
    data.set_text(
      serialize(
        [
          "dbpage_id" => self.dbpage_id,
          "type" => "nbpage"
        )
      )
    )
  end

  def OnDrop(data1, data2, data3, data4, data5, data6, data7)
    data = data5.data

    if is_numeric(data)
      dbpage = get_winMain().getDBPage(data)
      tables_sel = treeview_getSelection(dbpage.tv_tables)
      tables = [)
      foreach(tables_sel AS table_sel)
        tables[] = dbpage.dbconn.getTable(table_sel[0])
      end

      @ondrop_knj_clist = [
        "dbpage" => dbpage,
        "tables" => tables
      )
      pop = new knj_popup(
        [
          "copy" => _("Copy"),
          "move" => _("Move")
        ),
        [self, "OnDrop_knj_clist")
      )
    elsif data["type"] == "nbpage"
      dbpage_me = @dbpage
      dbpage_dropped = get_winMain().dbs_open[data[dbpage_id]]

      @ondrop_nbpage = dbpage_dropped

      pop = new knj_popup(
        [
          "copy_tables" => _("Copy tables to db")
        ),
        [self, "OnDrop_nbpage")
      )
    end
  end

  def OnDrop_nbpage(mode)
    if mode == "copy_tables"
      win_status = new WinStatus(get_winMain())
      win_status.SetStatus(0, _("Preparing..."))

      # The dbpage that we will read from.
      dbpage_dropped = @ondrop_nbpage

      # For making the SQL.
      sqlc = get_SQLC()
      sqlc.SetOutputType(@dbpage.dbconn.type)

      win_status.SetStatus(0, _("Reading list of tables."))
      tables_list = dbpage_dropped.dbconn.GetTables()
      my_tables = @dbconn.GetTables()

      win_status.SetStatus(0, _("Copying..."))
      foreach(tables_list AS table_data)
        copy_table = true
        copy_name = table_data[name]

        # Checking if a table by that name already exists.
        if my_tables
          foreach(my_tables AS my_table_d)
            if my_table_d[name] == table_data[name]
              newname = knj_input(_("Warning"), _("The table already exists. Please enter another name for this table:"), table_data[name])
              newname = trim(newname)

              foreach(my_tables AS my_table_check)
                if my_table_check[name] == newname
                  msgbox(_("Warning"), _("The name also exists - the table will not be copied - sorry"), "warning")
                  copy_table = false
                  break
                end
              end

              if newname != "cancel"
                copy_name = newname
              else
                copy_table = false
              end

              break
            end
          end
        end

        # Copying table.
        if copy_table == true
          columns_list = dbpage_dropped.dbconn.GetColumns(table_data[name])

          sql = sqlc.ConvertTable(copy_name, columns_list)
          @dbconn.query(sql)

          f_gdata = dbpage_dropped.dbconn.query("SELECT * FROM " . table_data[name])
          while(d_gdata = dbpage_dropped.dbconn.query_fetch_assoc(f_gdata))
            sql = sqlc.ConvertInsert(copy_name, d_gdata, columns_list)
            @dbconn.query(sql)
          end
        end
      end

      @dbpage.TablesUpdate(win_status)
      win_status.CloseWindow()
    end
  end

  # The user has drag'n'dropped a table from the tables-treeview to a notebook-dbpage-button - after the popup he has choosen to copy or move it... Here we copy or move the tables, as he has whished to do.
  def OnDrop_knj_clist(mode)
    try
      if mode == "copy" || mode == "move"
        status_copy = _("Copying data")
        tables = @ondrop_knj_clist["tables"]
        dbpage = @ondrop_knj_clist["dbpage"]

        # require files and show status-window.
        require_once("knjphpframework/functions_date.php")
        require_once("knjphpframework/win_status.php")
        win_status = new WinStatus()


        # get vars.
        conn_from_type = get_class(dbpage.dbconn.conn)
        conn_to_type = get_class(@dbconn.conn)


        # Go through each selected table.
        foreach(tables AS table)
          win_status.setStatus(0, sprintf(_("Reading columns from: %s"), table.get("name")), true)
          columns = table.getColumns()
          columns_arr = [)
          foreach(columns AS column)
            columns_arr[] = column.data
          end


          # Error-handeling - check if the table already exists.
          win_status.SetStatus(0, _("Checking if table already exists in the database."), true)
          tables_list = @dbconn.tables().getTables()
          foreach(tables_list AS value)
            if value.get("name") == table.get("name")
              raise sprintf(_("The table name: \"%s\", already exists in the database."), table.get("name")))
            end
          end


          # Make SQL and run on database.
          win_status.setStatus(0, _("Creating table and columns."), true)
          @dbconn.tables().createTable(table.get("name"), columns_arr)
          newtable = @dbconn.getTable(table.get("name"))


          # Copy data.
          d_cd = dbpage.dbconn.query("SELECT COUNT(*) AS count FROM " . table.get("name")).fetch()

          count = 0
          countt = d_cd["count"]
          show_errors = true
          errors = false
          win_status.setStatus(0, sprintf(_("Copying data (%s)"), "0/" . number_format(countt, 0)), true)
          @dbconn.insert_autocommit(250)

          f_gd = dbpage.dbconn.select(table.get("name"))
          while(d_gd = f_gd.fetch())
            if conn_from_type == "knjdb_mssql" && conn_to_type == "knjdb_mysql"
              foreach(d_gd AS col_name => row_value)
                col_ob = newtable.getColumn(col_name)
                if col_ob.data["type"] == "datetime"
                  # convert the data to a known date-format.

                  if !trim(row_value)
                    d_gd[col_name] = "0000-00-00 00:00:00"
                  elsif preg_match("/^([A-z]{3})\s+([0-9]{1,2})\s+([0-9]{1,4})\s+([0-9:]+)([A-z]{1,2})/", row_value, match)
                    month_no = date_month_str_to_no(strtolower(match[1]))
                    date_mysql = date[3] . "-" . month_no . "-" . date[2] . " " . date[4]
                    d_gd[col_name] = date("Y-m-d H:i:s", strtotime(row_value))
                  else
                    raise "Could not match the date-value (" . row_value . ").")
                  end
                end
              end
            end

            count++
            @dbconn.insert(table.get("name"), d_gd)
            win_status.setStatus(count / countt, status_copy . " (" . count . "/" . countt . ")")
          end

          @dbconn.insert_autocommit(false); # turn if off and commit the rest.


          # Copy indexes.
          foreach(table.getIndexes() AS index)
            cols = [)
            foreach(index.getColumns() AS col)
              cols[] = newtable.getColumn(col.get("name"))
            end

            newtable.addIndex(cols)
          end


          # Drop old table, if we are in "moving"-mode.
          if mode == "Move"
            win_status.SetStatus(1, _("Dropping old table."), true)
            table.drop()
            dbpage.TablesUpdate(win_status)
          end
        end

        # Updating knj_clist()'s on the GtkNotebook()'s.
        @dbpage.TablesUpdate()
        win_status.CloseWindow()
      end
    catch(Exception e)
      if win_status
        win_status.closeWindow()
      end

      knj_msgbox::error_exc(e)
      @dbpage.TablesUpdate()
    end
  end

  def ItemClicked(widget, event)
    if event.button == 3
      popup = new knj_popup(
        [
          "close" => _("Close"),
          "optimize" => _("Optimize"),
          "select_another" => _("Select another database"),
          "truncate_all" => _("Truncate all dbs"),
          "drop_all" => _("Drop all tables")
        ),
        [self, "ItemClicked_Activate")
      )
    end
  end

  def ItemClicked_Activate(mode)
    if mode == "close"
      get_winMain().CloseDatabaseClicked()
    elsif mode == "select_another"
      get_winMain().SelectOtherDbClicked()
    elsif mode == "truncate_all"
      get_winMain().TruncateAllClicked()
    elsif mode == "optimize"
      get_winMain().dbOptimize()
    elsif mode == "drop_all"
      if msgbox(_("Question"), _("Do you want to drop all the tables on this database?"), "yesno") == "yes"
        tables = get_winMain().getDBConn().tables().getTables()
        foreach(tables AS table)
          table.drop()
        end

        get_winMain().dbpage.tablesUpdate()
      end
    else
      raise "Invalid mode: " . mode)
    end
  end
end
