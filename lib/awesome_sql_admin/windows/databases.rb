
	# This class will let the user choose a new database, if he is working in a multi-database environment (mysql, pgsql or whatever).
	class WinDatabases
		attr_accessor :window				# A reference to the GtkWindow()-object used.
		attr_accessor :glade				# A reference to the GladeXML-object used.
		attr_accessor :dbconn				# A reference to the DBPage-object which is used.
		attr_accessor :tv_dbs				# A reference to the GtkTreeview, which contains a list of the databases.
		attr_accessor :args

		# The constructor of WinDatabases.
		def initialize(knjdb dbconn, args = null)
			@dbconn = dbconn
			@args = args

			if @dbconn.getType() != "mysql" && @dbconn.getType() != "pgsql"
				throw new Exception(gtext("You have to open either a MySQL- or a PostgreSQL database, before choosing this option."))
			}

			@glade = new GladeXML("glades/win_databases.glade")
			@glade.signal_autoconnect_instance(self)

			@window = @glade.get_widget("window")
			winsetting = new GtkSettingsWindow(@window, "win_databases")

			@tv_dbs = @glade.get_widget("tvDBs")
			treeview_addColumn(@tv_dbs, array(
					gtext("Name")
				)
			)

			@UpdateDBList()
			@window.show_all()
		}

		# Catches press-events from the databases-treeview (doubleclicks etc).
		def on_tvDBs_button_press_event(selection, event)
			if event.type == 5
				@ChooseDB(); # Double-click on the treeview.
			}
		}

		# Chooses the selected database.
		def ChooseDB
			require_once("knjphpframework/win_status.php")
			win_status = new WinStatus(array("window_parent" => @window))
			win_status.setStatus(0, gtext("Changing database."), true)

			value = treeview_getSelection(@tv_dbs)

			try
				db = @dbconn.dbs().getDB(value[0])
				state = @dbconn.dbs().chooseDB(db)
				win_status.setStatus(0.5, gtext("Reloading tables."), true)

				if self.args["opennewdbconn"]
					get_winMain().SpawnNewDB(@args["dbpage_title"], @dbconn)
				}else
					get_winMain().dbpage.tablesUpdate()
				}

				win_status.closeWindow()
				@closeWindow()
			}catch(Exception e)
				if win_status
					win_status.closeWindow()
				}
				msgbox(gtext("Warning"), e.getMessage(), "warning")
			}
		}

		# Reloads the list of databases.
		def UpdateDBList
			@tv_dbs.get_model().clear()
			foreach(@dbconn.dbs().getDBs() AS db)
				@tv_dbs.get_model().append(array(db.getName()))
			}
		}

		# Closes the window.
		def CloseWindow
			@window.destroy()
		}
	}
?>