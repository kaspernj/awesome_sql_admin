
	# This class contains each of the notebook-pages in the main window for each db-profile which is open.
	class DBPage extends GtkVBox
		public dbconn;					# A reference to the DBConn-object, which this class uses.
		attr_accessor :glade					# A reference to the GladeXML-object.
		attr_accessor :title					# The title of the DBPage.
		attr_accessor :id						# The ID of the DBPage.
		public tv_tables;				# A reference to the tables-treeview.
		public tv_columns;				# A reference to the columns-treeview.
		public tv_indexes;				# A reference to the indexes-treeview.

		/**
		 * The constructor.
		 *
		 * @param DBConn dbconn The DBConn-object which this DBPage should make use of.
		 * @param string title The title of the DBPage.
		 * @param int id The ID of the DBPage.
		*/
		def initialize(dbconn, title, id)
			parent::__construct()

			@dbconn = dbconn
			@title = title
			@id = id

			@glade = new GladeXML("glades/vbox_dbpage.glade")
			@glade.signal_autoconnect_instance(self)

			vbox_dbpage = @glade.get_widget("vbox_dbpage")
			vbox_dbpage.unparent()

			@add(vbox_dbpage)

			@tv_tables = @glade.get_widget("tvTables")
			@tv_tables.get_selection().set_mode(Gtk::SELECTION_MULTIPLE)
			treeview_addColumn(@tv_tables, array(
					gtext("Title"),
					gtext("Columns"),
					gtext("Rows")
				)
			)
			@tv_tables.get_selection().connect("changed", array(self, "TablesClicked"))
			@tv_tables.drag_source_set(Gdk::BUTTON1_MASK, array(array("text/plain", 0, 0)), Gdk::ACTION_COPY|Gdk::ACTION_MOVE); # Enables dragging FROM the clist.
			@tv_tables.connect("drag-data-get", array(self, "drag_data_save")); # Setting the dragged data-object.
			tables_settings = new GtkSettingsTreeview(@tv_tables, "dbpage_tables")

			@tv_columns = @glade.get_widget("tvColumns")
			treeview_addColumn(@tv_columns, array(
					gtext("Title"),
					gtext("Type"),
					gtext("Max length"),
					gtext("Not null"),
					gtext("Default"),
					gtext("Primary"),
					gtext("Auto incr")
				)
			)
			@tv_columns.get_selection().connect("changed", array(get_winMain(), "ColumnsClicked"))
			columns_settings = new GtkSettingsTreeview(@tv_columns, "dbpage_columns")

			paned_settings = new GtkSettingsPaned(@glade.get_widget("hpanedTablesColumns"), "dbpage_tablescolumns")

			@tv_indexes = @glade.get_widget("tvIndexes")
			treeview_addColumn(@tv_indexes, array(
					gtext("Title"),
					gtext("Columns")
				)
			)
			index_settings = new GtkSettingsTreeview(@tv_indexes, "dbpage_indexes")

			@TablesUpdate(); # Fill the treeview with tables.
		}

		def destroy
			@dbconn.close()
			unset(@dbconn, @tv_tables, @tv_columns, @tv_indexes, @glade)
			parent::destroy()
		}

		def drag_data_save(widget, context, data, info, time)
			# FIXME: It gave an error with pure serialize - somehow base64-encode fixed it?
			data.set_text(@id)
		}

		# Returns the DBConn-object for this object.
		def get_DBConn
			return @dbconn
		}

		# Returns the tables-treeview for this object.
		def get_TVTables
			return @tv_tables
		}

		# Returns the columns-treeview for this object.
		def get_TVColumns
			return @tv_columns
		}

		# Returns the indexes-treeview for this object.
		def get_TVIndexes
			return @tv_indexes
		}

		def on_tvTables_button_press_event(selection, event)
			if event.button == 3 # Handels the right-click-event.
				popup = new knj_popup(
					array(
						"browse" => gtext("Browse"),
						"create_new" => gtext("Create new"),
						"edit" => gtext("Edit"),
						"rename" => gtext("Rename"),
						"truncate" => gtext("Truncate"),
						"drop" => gtext("Drop"),
						"refresh" => gtext("Refresh"),
						"optimize" => gtext("Optimize")
					),
					array(self, "ClistTablesRightclickMenu")
				)
			elsif event.type == 5 # doubleclick.
				@ClistTablesRightclickMenu("browse")
			}
		}

		def on_tvColumns_button_press_event(selection, event)
			if event.button == 3 # Handels the right-click-event.
				popup = new knj_popup(
					array(
						"add_new" => gtext("Add new columns"),
						"add_index" => gtext("Add index for this column"),
						"drop" => gtext("Drop column")
					),
					array(self, "ClistColumnsRightclickmenu")
				)
			}
		}

		def on_tvIndexes_button_press_event(selection, event)
			if event.button == 3 # Handels the right-click-event.
				popup = new knj_popup(
					array("drop" => gtext("Drop index")),
					array(self, "ClistIndexRightclickmenu")
				)
			}
		}

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
				@tablesUpdate()
			elsif mode == "optimize"
				get_winMain().tableOptimize()
			}
		}

		def ClistColumnsRightclickmenu(mode)
			if mode == "add_new"
				get_winMain().ColumnAddClicked()
			elsif mode == "drop"
				get_winMain().ColumnRemoveClicked()
			elsif mode == "add_index"
				get_winMain().IndexAddClicked()
			}
		}

		def ClistIndexRightclickmenu(mode)
			if mode == "drop"
				get_winMain().IndexDropClicked()
			}
		}

		# Returns a single table, which is selected (treeview_getSelection() will return multiple).
		def getTable(ob = false)
			tables = treeview_getSelection(@tv_tables)
			table = tables[0]

			if ob
				return @dbconn.getTable(table[0])
			}else
				return table
			}
		}

		# Handels the event, when a new table is selected in the tables-treeview.
		def tablesClicked
			@tv_columns.get_model().clear()
			@tv_indexes.get_model().clear()

			table = @getTable()
			if !table
				return null
			}
			table_ob = @getTable(true)
			if !table_ob
				return null
			}

			foreach(table_ob.getColumns() AS column)
				self.tv_columns.get_model().append(array(
						column.get("name"),
						column.get("type"),
						column.get("maxlength"),
						column.get("notnull"),
						column.get("default"),
						column.get("primarykey"),
						column.get("autoincr")
					)
				)
			}

			foreach(table_ob.getIndexes() AS index)
				self.tv_indexes.get_model().append(array(
						index.get("name"),
						index.getColText()
					)
				)
			}

			get_winMain().updateCurrentVars()
		}

		# Reloads the tables in the treeview.
		def tablesUpdate(WinStatus win_status = null)
			@tv_columns.get_model().clear()
			@tv_tables.get_model().clear()

			if win_status
				win_status.setStatus(0, gtext("Adding tables to clist (querying)."), true)
			}

			tables = @dbconn.tables().getTables()
			count = 0
			countt = count(tables)
			foreach(tables AS key => table)
				if win_status
					count++
					win_status.setStatus(count / countt, sprintf(gtext("Adding tables to list (%s)."), table.get("name")), true)
				}

				count_rows = 0
				count_columns = 0

				count_rows = number_format(table.countRows(), 0, ",", ".")
				count_columns = count(table.getColumns())

				@tv_tables.get_model().append(array(table.get("name"), count_columns, count_rows))
			}

			if win_status
				win_status.closeWindow()
			}
		}
	}
?>