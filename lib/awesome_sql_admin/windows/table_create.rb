
	# *This class contains the controls for the table-creating window. **/
	class WinTableCreate
		attr_accessor :glade
		attr_accessor :window

		attr_accessor :columns				# The columns of the table from the database.
		attr_accessor :numb_columns		# The total count of columns.
		attr_accessor :columns_numkeys	# The columns with the key as count.

		attr_accessor :labels				# All the GtkLabels for the columns.
		attr_accessor :names				# The GtkEntry's which contains the column-names.
		attr_accessor :maxlengths			# The GtkEntry's which contains the maxlength.
		attr_accessor :types				# The GtkComboBox's which contain the column-type.
		attr_accessor :defaults			# The GtkEntry's which contains the column-defaults.
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
			}

			if columns
				foreach(columns AS column)
					@columns[column.data["name"]] = column
					@columns_numkeys[] = column
				}
			}

			@numb_columns = numb_columns
			temp = array()

			table = new GtkTable()
			lab_name = new GtkLabel(gtext("Name"))
			lab_name.set_alignment(0, 0.5)

			lab_type = new GtkLabel(gtext("Type"))
			lab_type.set_alignment(0, 0.5)

			lab_maxlength = new GtkLabel(gtext("Max length"))
			lab_maxlength.set_alignment(0, 0.5)

			lab_default = new GtkLabel(gtext("Default"))
			lab_default.set_alignment(0, 0.5)

			lab_notnull = new GtkLabel(gtext("Not null"))
			lab_notnull.set_alignment(0, 0.5)

			lab_autoincr = new GtkLabel(gtext("Auto inc"))
			lab_autoincr.set_alignment(0, 0.5)

			lab_prim = new GtkLabel(gtext("Prim key"))
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

			column_types = array(
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
			}

			while(count < self.numb_columns)
				@labels[count] = new GtkLabel(gtext("Column") . " " . (count + 1))
					@labels[count].set_alignment(0, 0.5)

				@names[count] = new GtkEntry()
					@names[count].set_size_request(90, -1)

				@maxlengths[count] = new GtkEntry()
					@maxlengths[count].set_max_length(8)
					@maxlengths[count].set_size_request(50, -1)

				@types[count] = GtkComboBox::new_text()
				foreach(column_types AS value)
					@types[count].append_text(strtoupper(value))
				}
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
						}
					}else
						@maxlengths[count].set_text(column.get("maxlength"))
					}

					if @dbconn.type == "access" && column.get("type") == "counter"
						# sets to integer if the type is a Access-counter.
						@types[count].set_active(1)
					}else
						@types[count].set_active(types[column.get("type")])
					}

					if column.get("notnull") == "yes"
						@notnull[count].clicked()
					}

					if column.get("primarykey") == "yes" || column.get("type") == "counter"
						@prim[count].clicked()
					}

					if column.get("type") == "counter" || column.get("autoincr") == "yes"
						@autoincr[count].clicked()
					}
				elsif mode == "createtable" || mode == "addcolumns"
					@notnull[count].clicked()
				}

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
			}

			@glade.get_widget("vbox_columns").pack_start(table, false, false)
			@window.show_all()
			table.show_all()
		}

		# *Closes the window. */
		def CloseWindow
			@window.destroy()
		}

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
							msgbox(gtext("Warning"), gtext("A column has the same name as an existing column."), "warning")
							return false
						}
					}
				}

				if type == "VARCHAR"
					type = "varchar"
				elsif type == "INTEGER"
					type = "int"
				}else
					type = strtolower(type)
				}

				if !prim
					prim = "no"
				}else
					prim = "yes"
				}

				if !autoincr
					autoincr = "no"
				}else
					autoincr = "yes"
				}

				if !notnull
					notnull = "no"
				}else
					notnull = "yes"
				}

				# Recognizable error-handeling.
				if @dbconn.type == "access" && type == "int" && maxlength
					msgbox(gtext("Warning"), gtext("Access does not support a maxlength-value on a integer-column.\n\nPlease leave the maxlength-textfield empty on the column: '") . name . "'.", "warning")
					return false
				}

				if maxlength && type != "decimal" && type != "enum" && !is_numeric(maxlength)
					msgbox(gtext("Warning"), gtext("You have filled the maxlength-textfield with a non-numeric-value.\n\nPlease change this to an empty- or a numeric value at the column: '") . name . "'.", "warning")
					return false
				}

				if prim == "yes" && type != "int"
					msgbox(gtext("Warning"), gtext("The primary key can only be a integer at the column: '") . name . "'.", "warning")
					return false
				}

				if autoincr == "yes" && type != "int"
					msgbox(gtext("Warning"), gtext("You cant set autoincrement on a varchar at the column: '") . name . "'.")
					return false
				}
				# End of the recognizable error-handeling.

				newcolumns[] = array(
					"name" => name,
					"type" => type,
					"primarykey" => prim,
					"notnull" => notnull,
					"maxlength" => maxlength,
					"default" => default
				)
			}

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
					}
				elsif @mode == "createtable"
					get_winMain().getDBConn().tables().createTable(@tablename, newcolumns)
				}

				# Update main-window and close this window.
				get_winMain().dbpage.TablesUpdate()
				@CloseWindow()
			}catch(TralaException e)
				knj_msgbox::error_exc(e)
			}
		}
	}
?>