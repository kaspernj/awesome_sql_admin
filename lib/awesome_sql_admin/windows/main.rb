
	# This class controls the main window.
	class WinMain
		attr_accessor :glade					# Reference to the GladeXML()-object.
		public window;					# Reference to the GtkWindow()-object.
		attr_accessor :nb_dbs					# Reference to the GtkNotebook()-object which contains the openned database-profiles.
		attr_accessor :dbs_open_count = 0	# The count of DBPages. This is used to determine their ID's.
		public dbpage;					# The current DBPage, which is being used.
		public dbconn;					# The current DBConn, which is being used.

		# The constructor. This spawns the GladeXML()-object and sets some variables.
		def initialize
			@glade = new GladeXML("glades/win_main.glade")
			@glade.signal_autoconnect_instance(self)

			@window = @glade.get_widget("window")
			winsetting = new GtkSettingsWindow(@window, "win_main")

			@nb_dbs = @glade.get_widget("nbDbs")
			@nb_dbs.connect_after("switch-page", array(self, "ChangeActiveDB"))

			@window.show_all()
		}

		# Returns the current DBConn.
		def getDBConn
			return @dbconn
		}

		# Return a DBPage()-object from the ID.
		def getDBPage(id)
			return @dbs_open[id]
		}

		/**
		 * Spawns a new page on the notebook and creates the DBPage-object for it.
		 *
		 * @param string title The title of the DBPage.
		 * @param DBConn dbconn The DBConn which should be used with the DBPage.
		*/
		def SpawnNewDB(title, newdbconn)
			# Spawn a new page on the main GtkNotebook().
			require_once("gui/class_DBPage.php")
			dbpage = new DBPage(newdbconn, title, @dbs_open_count)
			@dbs_open[self.dbs_open_count] = dbpage

			# Used for dragging for identifying which dbpage the dragged element belong to.
			dbpage.tv_tables.other["dbpage_id"] = @dbs_open_count

			# removes the default page, if it is shown.
			if !self.nb_dbs.default_page_removed
				@nb_dbs.default_page_removed = true
				@nb_dbs.remove_page(0)
			}

			# Require the Notebook_Page()-class.
			require_once("gui/class_Notebook_Page.php")
			nb_page = new WinMain_Notebook_Page(title, dbpage, self)

			pageid = self.nb_dbs.append_page(
				dbpage,
				nb_page
			)

			nb_page.dbpage_id = @dbs_open_count
			dbpage.dbpage_id = @dbs_open_count

			# refresh notebook. sets focus on the new page.
			@nb_dbs.show_all()
			@nb_dbs.set_current_page(pageid)

			@dbs_open_count++
		}

		# Sets the comfort-variables, when a new page has been selected.
		def ChangeActiveDB
			@dbpage = @nb_dbs.get_nth_page(self.nb_dbs.get_current_page())

			# Then we set the main-variables to refelect current page.
			@tv_tables = @dbpage.get_TVTables()
			@tv_columns = @dbpage.get_TVColumns()
			@tv_indexes = @dbpage.get_TVIndexes()
			@dbconn = @dbpage.get_DBConn()
		}

		# Open a new database-profile.
		def OpenDatabaseClicked
			require_once("gui/win_dbprofiles.php")
			win_dbprofiles = new WinDBProfiles(self)
		}

		# Close the current database-profile.
		def CloseDatabaseClicked
			if !self.getDBConn()
				msgbox(gtext("Warning"), gtext("There is no database-connection open at this time."), "warning")
				return null
			}

			@dbpage.destroy()
		}

		# Truncates all tabels on all databases.
		def TruncateAllClicked
			if !self.getDBConn().conn
				msgbox(gtext("Warning"), gtext("You need to open a database, before you can truncate its databases"), "warning")
				return null
			}

			if msgbox(gtext("Question"), gtext("Do you really want to truncate all databases on the current connection?"), "yesno") != "yes"
				return null
			}

			try
				dbs = @getDBConn().GetDBs()

				foreach(dbs AS value)
					@getDBConn().ChooseDB(value)
					tables = @getDBConn().GetTables(value)

					foreach(tables AS table)
						@getDBConn().TruncateTable(table["name"])
					}
				}
			}catch(Exception e)
				msgbox(gtext("Warning"), sprintf(gtext("An error occurred:\n\n%s"), e.getMessage()), "warning")
			}

			@dbpage.TablesUpdate()
		}

		# Select another database than the default one in the database, if the current type if MySQL, PostgreSQL or whatever.
		def SelectOtherDbClicked(knjdb = null, args = null)
			if get_class(knjdb) != "knjdb"
				knjdb = @dbpage.dbconn
			}

			if !is_array(args)
				args = null
			}

			try
				require_once("gui/win_databases.php")
				win_dbs = new WinDatabases(knjdb, args)
			}catch(Exception e)
				msgbox(gtext("Warning"), e.getMessage(), "warning")
			}
		}

		# Add a index to the currently selected table and column.
		def IndexAddClicked
			try
				if !self.getDBConn()
					msgbox(gtext("Warning"), gtext("Please open a database before trying to add a index."), "warning")
					return null
				}

				table = @getTable()
				table_ob = @dbconn.getTable(table[0])
				if !table
					msgbox(gtext("Warning"), gtext("Please select a table and try again."), "warning")
					return null
				}

				column = treeview_getSelection(@tv_columns)
				column_ob = table_ob.getColumn(column[0])

				if !column_ob
					msgbox(gtext("Warning"), gtext("Please select a column to create a index of."), "warning")
					return null
				}

				table_ob.addIndex(array(column_ob))

				@dbpage.TablesClicked()
				msgbox(gtext("Information"), gtext("The index was created with a success."), "info")
			}catch(Exception e)
				msgbox(gtext("Warning"), sprintf(gtext("An error occurred:\n\n%s"), e.getMessage()), "warning")
			}
		}

		# Drop the selected index.
		def IndexDropClicked
			try
				if !self.getDBConn()
					msgbox(gtext("Warning"), gtext("Please open a database before trying to drop a index."), "warning")
					return null
				}

				index = treeview_getSelection(@tv_indexes)
				table = @getTable(true)

				if !index
					msgbox(gtext("Warning"), gtext("Please select a index to drop and try again."), "warning")
					return null
				}
				index_ob = table.getIndexByName(index[0])

				table.removeIndex(index_ob)
			}catch(Exception e)
				knj_msgbox::error_exc(e)
			}

			@dbpage.TablesClicked()
		}

		def RunSQLClicked
			if !self.getDBConn().conn
				msgbox(gtext("Warning"), gtext("You must open a database, before you can execute a SQL-script."), "warning")
				return null
			}

			require_once("gui/win_runsql.php")
			win_runsql = new WinRunSQL(@dbpage)
		}

		# Backup the current database.
		def BackupDBClicked
			if !self.getDBConn()
				msgbox(gtext("Warning"), gtext("You must open a database, before you can do a backup."), "warning")
				return null
			}

			require_once("gui/win_backup.php")
			win_backup = new WinBackup(self)
		}

		def getTable(ob = false)
			return @dbpage.getTable(ob)
		}

		def getDB
			return @dbpage.getDB()
		}

		# Rename the selected table.
		def TableRenameClicked
			if !self.getDBConn()
				msgbox(gtext("Warning"), gtext("Please open a database before trying to rename a table."), "warning")
				return false
			}

			# Getting the marked table and run some possible error-handeling.
			tables = treeview_getSelection(@tv_tables)
			if count(tables) <= 0
				msgbox(gtext("Warning"), gtext("Please select the table, that you would like to rename."), "warning")
				return false
			}

			foreach(tables AS table)
				# Getting the new table-name from the user.
				tablename = knj_input(gtext("New table name"), gtext("Please enter the new table-name:"), table[0])
				if tablename == "cancel"
					break
				}

				# If he has enteret the same name.
				if strtolower(tablename) == strtolower(table[0])
					msgbox(gtext("Warning"), gtext("The entered name was the same as the current table-name."), "warning")
					break
				}

				# Checking if the new table-name if valid.
				if !preg_match("/^[a-zA-Z][a-zA-Z0-9_]+/", tablename, match)
					msgbox(gtext("Warning"), gtext("The enteret name was not a valid table-name."), "warning")
					break
				}

				# Renaming table and refreshing treeviews.
				try
					@getDBConn().getTable(table[0]).rename(tablename)
				}catch(Exception e)
					knj_msgbox::error_exc(e)
				}
			}

			@dbpage.TablesUpdate()
		}

		# Edit the selected table.
		def TableEditClicked
			if !self.getDBConn()
				msgbox(gtext("Warning"), gtext("Please open a database before trying to edit a table."), "warning")
				return null
			}

			table = @getTable()
			if !table
				msgbox(gtext("Warning"), gtext("You have to select a table to edit."), "warning")
				return null
			}

			# require and show the window-class.
			require_once("gui/win_table_create.php")
			win_table_create = new WinTableCreate(table[0], "editcolumns")
		}

		# Truncate the selecting table, leaving it empty.
		def TableTruncate
			try
				if !self.getDBConn()
					throw new Exception(gtext("Please open a database before trying to truncate it."))
				}

				tables = treeview_getSelection(@tv_tables)
				if count(tables) <= 0
					throw new Exception(gtext("You have to select a table to truncate."))
				}

				# Confirm and truncate.
				foreach(tables AS table)
					table_ob = @dbconn.getTable(table[0])

					if msgbox(gtext("Question"), sprintf(gtext("Do you want to truncate the table: %s?"), table[0]), "yesno") == "yes"
						table_ob.truncate()
					}
				}
			}catch(Exception e)
				knj_msgbox::error_exc(e)
			}

			@dbpage.TablesUpdate()
		}

		# Update the vars, which make it easier to work with the current selected database-profile.
		def updateCurrentVars
			@tv_tables = @dbpage.get_TVTables()
			@tv_columns = @dbpage.get_TVColumns()
			@tv_indexes = @dbpage.get_TVIndexes()
		}

		# Add new columns to the selected table.
		def ColumnAddClicked
			if !self.getDBConn()
				msgbox(gtext("Warning"), gtext("Please open a database before trying to add a column."), "warning")
				return null
			}

			table = @getTable()
			if !table
				msgbox(gtext("Warning"), gtext("You have to select a table to add columns to."), "warning")
				return null
			}

			input = knj_input(gtext("Number of columns"), gtext("Write the number of columns, you would like to add to the table:"))



			if input === false
				return null
			elsif !is_numeric(input)
				msgbox(gtext("Warning"), gtext("Please write numbers only. Try again."), "warning")
				return null
			}

			# require and show the window-class.
			require_once("gui/win_table_create.php")
			win_column_add = new WinTableCreate(table[0], "addcolumns", input)
		}

		# Remove the selected column from the table.
		def ColumnRemoveClicked
			try
				if !self.getDBConn()
					msgbox(gtext("Warning"), gtext("Please open a database before trying to remove a column."), "warning")
					return false
				}

				column = treeview_getSelection(@tv_columns)
				table = @getTable()
				table_ob = @dbconn.getTable(table[0])
				column_ob = table_ob.getColumn(column[0])

				if !column
					msgbox(gtext("Warning"), gtext("You have not selected a column."), "warning")
					return false
				}

				if msgbox(gtext("Question"), sprintf(gtext("Do you want to remove the selected column: %s?"), column[0]), "yesno") == "yes"
					table_ob.removeColumn(column_ob)
				}
			}catch(Exception e)
				knj_msgbox::error_exc(e)
			}

			@dbpage.TablesClicked()
		}

		# Create new database (if the type is MySQL, PostgreSQL or whatever).
		def CreateNewDatabaseClicked
			if !self.getDBConn()
				msgbox(gtext("Warning"), gtext("Please open a database-profile first."), "warning")
				return false
			}

			type = @getDBConn().getType()
			if type != "mysql" && type != "pgsql"
				msgbox(gtext("Warning"), sprintf(gtext("You cant create new databases of af the current dbtype: %s."), type), "warning")
				return false
			}

			name = knj_input(gtext("New database name"), gtext("Please enter the name of the new database-type:"))
			if name == false
				return false
			}

			# Create and choose the new database.
			try
				@getDBConn().dbs().createDB(array("name" => name))
				db = @getDBConn().dbs().getDB(name)
				@getDBConn().dbs().chooseDB(db)
				@dbpage.tablesUpdate()
			}catch(Exception e)
				msgbox(gtext("Warning"), e.getMessage(), "warning")
				return false
			}
		}

		def dbOptimize
			try
				db = @getDBConn().dbs().getCurrentDB()
				db.optimize()
				msgbox(gtext("Information"), gtext("The database was optimized."), "info")
			}catch(Exception e)
				msgbox(gtext("Warning"), e.getMessage(), "warning")
			}
		}

		# Create a new table in the database.
		def TableCreateClicked
			if !self.getDBConn().conn
				msgbox(gtext("Warning"), gtext("Currently there is no active database."), "warning")
				return null
			}

			tablename = knj_input(gtext("Name"), gtext("Please enter the table name:"))
			if tablename === false
				return null
			}

			if !preg_match("/^[a-zA-Z][a-zA-Z0-9_]+/", tablename, match)
				msgbox(gtext("Warning"), gtext("The name you chooce is not a valid table-name."), "warning")
				return null
			}

			columns_count = knj_input(gtext("Columns"), gtext("Please enter the number of columns you want:"))
			if columns_count === false
				return null
			}

			require_once("gui/win_table_create.php")
			win_table_create = new WinTableCreate(tablename, "createtable", columns_count)
		}

		# Browse the table.
		def TableBrowseClicked
			if !self.tv_tables
				msgbox(gtext("Warning"), gtext("Please open a database-profile first."), "warning")
				return null
			}

			table = @getTable()
			require_once("gui/win_table_browse.php")
			win_table_browse = new WinTableBrowse(@dbpage, table[0])
		}

		# Drop the selected table.
		def TableDropClicked
			if !self.tv_tables
				msgbox(gtext("Warning"), gtext("Please open a database-profile first."), "warning")
				return false
			}

			tables = treeview_getSelection(@tv_tables)
			if count(tables) <= 0
				msgbox(gtext("Warning"), gtext("You have not selected a table to drop."), "warning")
				return false
			}

			foreach(tables AS table)
				if msgbox(gtext("Question"), sprintf(gtext("Are you sure you want to drop the table: %s?"), table[0]), "yesno") == "yes"
					@getDBConn().getTable(table[0]).drop()
				}
			}

			@dbpage.TablesUpdate()
		}

		def tableOptimize
			table = @getTable(true)

			if !table
				msgbox(gtext("Warning"), gtext("Please choose a table."), "warning")
				return null
			}

			table.optimize()
			msgbox(gtext("Information"), gtext("The table was optimized."), "info")
		}

		def ColumnsClicked

		}

		# Handels the event when the window is closed. Stops the main-loop and terminating the application.
		def CloseWindow
			@window.hide()
			gtk2_refresh()
			Gtk::main_quit()
		}
	}
?>