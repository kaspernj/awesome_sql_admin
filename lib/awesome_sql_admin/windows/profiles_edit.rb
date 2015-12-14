
	# This class controls the window when making and editing db-profiles.
	class WinDBProfilesEdit
		attr_accessor :glade
		attr_accessor :window
		attr_accessor :win_dbprofile
		attr_accessor :mode
		attr_accessor :types
		attr_accessor :types_text
		attr_accessor :types_nr
		attr_accessor :edit_data

		# The constructor of WinDBProfilesEdit.
		def initialize(WinDBProfiles win_dbprofile, mode = "add")
			@glade = new GladeXML("glades/win_dbprofiles_edit.glade")
			@glade.signal_autoconnect_instance(self)

			@window = @glade.get_widget("window")
			winsetting = new GtkSettingsWindow(@window, "win_dbprofiles_edit")

			@win_dbprofile = win_dbprofile
			@window.set_transient_for(win_dbprofile.window)
			@mode = mode

			# Typer der kan bruges.
			@types["mysql"] = "MySQL"
			@types["mysqli"] = "MySQLi"
			@types["pgsql"] = "PostgreSQL"
			@types["sqlite"] = "SQLite"
			@types["sqlite3"] = "SQLite3"
			@types["mssql"] = "MS-SQL"
			@types["access"] = "Access"

			@types_text["mysql"] = 0
			@types_text["mysqli"] = 1
			@types_text["pgsql"] = 2
			@types_text["sqlite"] = 3
			@types_text["sqlite3"] = 4
			@types_text["mssql"] = 5
			@types_text["access"] = 6

			@types_nr[0] = "mysql"
			@types_nr[1] = "mysqli"
			@types_nr[2] = "pgsql"
			@types_nr[3] = "sqlite"
			@types_nr[4] = "sqlite3"
			@types_nr[5] = "mssql"
			@types_nr[6] = "access"

			require_once("knjphpframework/functions_combobox.php")
			combobox_init(@glade.get_widget("cmbType"))
			foreach(@types AS value)
				@glade.get_widget("cmbType").append_text(value)
			}
			@glade.get_widget("cmbType").set_active(0)

			if @mode == "edit"
				# NOTE: Remember that the tv_profiles is in multiple mode, so it is possible to open more than one database at a time. This affects the returned array from treeview_getSelection().
				editvalue = treeview_getSelection(@win_dbprofile.tv_profiles)
				@edit_data = get_myDB().selectsingle("profiles", array("nr" => editvalue[0][0]))

				if file_exists(self.edit_data[location])
					@glade.get_widget("fcbLocation")	->set_filename(self.edit_data[location])
				}

				@glade.get_widget("texIP")			->set_text(self.edit_data[location])
				@glade.get_widget("texTitle")		->set_text(self.edit_data[title])
				@glade.get_widget("texUsername")	->set_text(self.edit_data[username])
				@glade.get_widget("texPassword")	->set_text(self.edit_data[password])
				@glade.get_widget("texDatabase")	->set_text(self.edit_data[database])
				@glade.get_widget("texPort")			->set_text(self.edit_data[port])
				@glade.get_widget("cmbType")			->set_active(self.types_text[self.edit_data[type]])
			}

			@window.show_all()
			@validateType()
		}

		# Hides unrelevant widgets based on the choosen type of database.
		def validateType
			active = @types_nr[self.glade.get_widget("cmbType").get_active()]
			if active == "mysql" || active == "postgresql" || active == "mysqli" || active == "mssql"
				@glade.get_widget("texIP").show()
				@glade.get_widget("texUsername").show()
				@glade.get_widget("texPassword").show()
				@glade.get_widget("texPort").show()
				@glade.get_widget("texDatabase").show()

				@glade.get_widget("labIP").show()
				@glade.get_widget("labUsername").show()
				@glade.get_widget("labPassword").show()
				@glade.get_widget("labPort").show()
				@glade.get_widget("labDatabase").show()

				@glade.get_widget("fcbLocation").hide()
				@glade.get_widget("labLocation").hide()
				@glade.get_widget("btnNewFile").hide()
			elsif active == "sqlite" || active == "access" || active == "sqlite3"
				@glade.get_widget("texIP").hide()
				@glade.get_widget("texUsername").hide()
				@glade.get_widget("texPassword").hide()
				@glade.get_widget("texPort").hide()
				@glade.get_widget("texDatabase").hide()

				@glade.get_widget("labIP").hide()
				@glade.get_widget("labUsername").hide()
				@glade.get_widget("labPassword").hide()
				@glade.get_widget("labPort").hide()
				@glade.get_widget("labDatabase").hide()

				@glade.get_widget("fcbLocation").show()
				@glade.get_widget("labLocation").show()
				@glade.get_widget("btnNewFile").show()
			}
		}

		# Saves the database-profile and closes the window.
		def SaveClicked
			nr =			@edit_data[nr]
			title =		@glade.get_widget("texTitle").get_text()
			type =		@types_nr[self.glade.get_widget("cmbType").get_active()]
			port =		@glade.get_widget("texPort").get_text()
			location =	@glade.get_widget("fcbLocation").get_filename()
			ip = 		@glade.get_widget("texIP").get_text()
			username =	@glade.get_widget("texUsername").get_text()
			password =	@glade.get_widget("texPassword").get_text()
			db =			@glade.get_widget("texDatabase").get_text()

			if type == "mysql" || type == "mysqli"|| type == "postgresql" || type == "mssql"
				location = ip
			}

			if @mode == "edit"
				get_myDB().update("profiles", array(
						"title" => title,
						"type" => type,
						"port" => port,
						"location" => location,
						"username" => username,
						"password" => password,
						"database" => db
					), array("nr" => nr)
				)
			elsif @mode == "add"
				get_MyDB().insert("profiles", array(
						"title" => title,
						"type" => type,
						"port" => port,
						"location" => location,
						"username" => username,
						"password" => password,
						"database" => db
					)
				)
			}

			@win_dbprofile.UpdateCList()
			@closeWindow()
		}

		# Closes the window.
		def closeWindow
			@window.destroy()
			unset(@glade, @window, @win_dbprofile); # Clean memory.
		}

		# Creates a new database-file (just an empty file actually).
		def on_btnNewFile_clicked
			filename = dialog_saveFile::newDialog()
			if filename
				file_put_contents(filename, "")
				@glade.get_widget("fcbLocation").set_filename(filename)
			}
		}
	}
?>