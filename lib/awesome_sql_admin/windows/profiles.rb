
	# This class contains the window when showing the different kind of db-profiles.
	class WinDBProfiles
		attr_accessor :glade
		public window
		attr_accessor :win_main
		public tv_profiles

		# The constructor.
		def initialize(win_main)
			@glade = new GladeXML("glades/win_dbprofiles_open.glade")
			@glade.signal_autoconnect_instance(self)

			@window = @glade.get_widget("window")
			winsetting = new GtkSettingsWindow(@window, "win_dbprofiles")

			@win_main = win_main
			@window.set_transient_for(self.win_main.window)

			@tv_profiles = @glade.get_widget("tvDBProfiles")
			treeview_addColumn(@tv_profiles, array(
					"ID",
					gtext("Title"),
					gtext("Type"),
					gtext("Database")
				)
			)
			@tv_profiles.get_column(0).set_visible(false)
			@tv_profiles.get_selection().set_mode(Gtk::SELECTION_MULTIPLE)
			settings_profiles = new GtkSettingsTreeview(@tv_profiles, "dbprofiles_profiles")

			@UpdateCList()
			@window.show_all()
		}

		# Handels the event when the enter-key is pressed while the treeview has focus (runs the connect-event).
		def on_tvDBProfiles_key_press_event(widget, event)
			if event.keyval == Gdk::KEY_Return || event.keyval == Gdk::KEY_KP_Enter
				@ConnectClicked()
			}
		}

		# Updates the treeview with profiles.
		def UpdateCList
			@tv_profiles.get_model().clear()
			f_gp = get_MyDB().select("profiles", null, array("orderby" => "title"))
			while(d_gp = f_gp.fetch())
				self.tv_profiles.get_model().append(array(
						d_gp["nr"],
						d_gp["title"],
						d_gp["type"],
						d_gp["database"]
					)
				)
			}
		}

		# Handels the event, when a button-press-event has been initialized on the treeview-object.
		def on_tvDBProfiles_button_press_event(selection, event)
			if event.type == 5 # Double-clicked.
				@ConnectClicked()
			}
		}

		# Handels the event when the connect-button is clicked.
		def ConnectClicked
			profiles = treeview_getSelection(@tv_profiles)
			if !profiles
				return null
			}

			# Show a status-window for opening the database.
			require_once("knjphpframework/win_status.php")
			win_status = new WinStatus(array("window_parent" => @window))

			try
				foreach(profiles AS value)
					d_gd = get_MyDB().selectsingle("profiles", array("nr" => value[0]))
					if !d_gd
						msgbox(gtext("Warning"), sprintf(gtext("Could not find the database-profile for: %s."), value[1]), "warning")
						return null
					}

					win_status.SetStatus(0, sprintf(gtext("Opening database: %s."), d_gd["title"]), true)
					@openProfile(d_gd)
				}

				win_status.CloseWindow()
				@CloseWindow()
			}catch(Exception e)
				win_status.CloseWindow()
				knj_msgbox::error_exc(e)
			}
		}

		def openProfile(d_gd)
			try
				# Open the database.
				if d_gd["type"] == "mysql" || d_gd["type"] == "mysqli" || d_gd["type"] == "pgsql" || d_gd["type"] == "mssql"
					load_arr = array(
						"type" => d_gd["type"],
						"host" => d_gd["location"],
						"db" => d_gd["database"],
						"user" => d_gd["username"],
						"pass" => d_gd["password"],
						"port" => d_gd["port"]
					)

					if !load_arr["db"]
						load_db_window = true
					}
				elsif d_gd["type"] == "sqlite" || d_gd["type"] == "sqlite3"
					# SQLite extension is already loaded, since knjSQLAdmin itself uses this kind of database.
					if !file_exists(d_gd["location"])
						if msgbox(gtext("Warning"), gtext("The database could not be found. Do you want to create it?\n\n") . d_gd["location"], "yesno") == "yes"
							fp = fopen(d_gd["location"], "w")

							if !fp
								throw new Exception(gtext("The database could not be created."))
							}

							fclose(fp)
						}else
							throw new Exception(sprintf(gtext("The file could not be found - aborting.\n\n%s"), d_gd["location"]))
						}
					}

					if d_gd["type"] == "sqlite"
						type = "sqlite2"
						dbtype = ""
					elsif d_gd["type"] == "sqlite3"
						type = "pdo"
						dbtype = "sqlite3"
					}

					load_arr = array(
						"type" => type,
						"dbtype" => dbtype,
						"path" => d_gd["location"]
					)
				elsif d_gd["type"] == "access"
					if !file_exists(d_gd["location"])
						if msgbox(gtext("Warning"), d_gd["location"] . gtext(" does not exist. Do you want to create an empty Access database?"), "yesno") == "yes"
							copy("Data/Access/empty.mdb", d_gd["location"])
						}else
							throw new Exception(sprintf(gtext("The file \"%s\" could not be found - aborting.", d_gd["location"])))
						}
					}

					load_arr = array(
						"type" => "access",
						"location" => d_gd["location"]
					)
				}else
					throw new Exception(gtext("The database-type wasnt given - aborting."))
				}

				newdbconn = new knjdb()
				newdbconn.setOpts(load_arr)

				if load_db_window
					@win_main.SelectOtherDbClicked(newdbconn, array("opennewdbconn" => true, "dbpage_title" => d_gd["title"]))
				}else
					spawnid = @win_main.SpawnNewDB(d_gd["title"], newdbconn)
				}
			}catch(Exception e)
				msgbox(gtext("Warning"), e.getMessage(), "warning")
			}
		}

		# Handels the event, when the add-button has been clicked.
		def AddClicked
			require_once("win_dbprofiles_edit.php")
			win_dbprofile_edit = new WinDBProfilesEdit(self, "add")
		}

		# Handels the event, when the edit-button has been clicked.
		def EditClicked
			require_once("win_dbprofiles_edit.php")

			value = treeview_getSelection(@tv_profiles)
			if !value
				msgbox(gtext("Warning"), gtext("You have to choose a profile to edit first."), "warning")
				return null
			}

			win_dbprofile_edit = new WinDBProfilesEdit(self, "edit")
		}

		# Handels the event, when the delete-button has been clicked.
		def DelClicked
			profiles = treeview_getSelection(@tv_profiles)
			if !profiles
				msgbox(gtext("Warning"), gtext("You have to choose a profile to delete first."), "warning")
				return null
			}

			foreach(profiles AS value)
				if msgbox(gtext("Question"), sprintf(gtext("Do you want to delete the chossen profile: %s?"), value[1]), "yesno") == "yes"
					get_MyDB().delete("profiles", array("nr" => value[0]))
				}
			}

			@UpdateCList()
		}

		# Closes the window.
		def CloseWindow
			@window.hide()
			gtk2_refresh()
			@window.destroy()
			unset(@window, @glade, @tv_profiles, @win_main); # clean memory.
		}
	}
?>