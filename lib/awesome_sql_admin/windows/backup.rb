
	# The class controls the backup-window and the execution of the functions in it
	class WinBackup
		attr_accessor :glade
		attr_accessor :window
		attr_accessor :dbconn
		attr_accessor :tv_tables
		attr_accessor :ch_structure

		# The constructor of WinBackup.
		def initialize(win_main)
			@glade = new GladeXML("glades/win_dbexport.glade")
			@glade.signal_autoconnect_instance(self)
			@window = @glade.get_widget("window")
			winsetting = new GtkSettingsWindow(@window, "win_backup")

			@win_main = win_main
			@dbconn = win_main.dbconn

			@tv_tables = @glade.get_widget("tvTables")
			@tv_tables.get_selection().set_mode(Gtk::SELECTION_MULTIPLE)
			treeview_addColumn(@tv_tables, array(gtext("Tablename")))

			tables = @dbconn.tables().getTables()
			foreach(tables AS table)
				@tv_tables.get_model().append(array(table.get("name")))
			}

			require_once("knjphpframework/functions_combobox.php")
			combobox_init(@glade.get_widget("comFormat"))
			@glade.get_widget("comFormat").append_text("MySQL")
			@glade.get_widget("comFormat").append_text("PostgreSQL")
			@glade.get_widget("comFormat").append_text("SQLite2")
			@glade.get_widget("comFormat").append_text("SQLite3")
			@glade.get_widget("comFormat").append_text("MS-SQL")
			@glade.get_widget("comFormat").append_text("Access")
			@glade.get_widget("comFormat").set_active(0)

			@window.show_all()
		}

		# Shows the window where you can choose to save the file.
		def SaveClicked
			# Validating if any tables have been choosen.
			values = treeview_getAll(@tv_tables)
			if !values
				msgbox(gtext("Warning"), gtext("You have to choose the tables, that you want to export."), "warning")
				return false
			}

			# Prompting for a directory to place the backup-file in and register events. At the last showing the window.
			filename = dialog_saveFile::newDialog()
			if filename
				@ExportToFile(filename)
			}
		}

		# Export the choosen tables to the choosen file and closes the window.
		def ExportToFile(filename)
			win_status = new WinStatus(array("window_parent" => @window))
			win_status.SetStatus(0, gtext("Preparing the backup-process..."), true)

			# Get the format.
			format = @glade.get_widget("comFormat").get_active_text()
			if format == "MySQL"
				format = "mysql"
			elsif format == "PostgreSQL"
				format = "pgsql"
			elsif format == "SQLite2"
				format = "sqlite2"
			elsif format == "SQLite3"
				format = "sqlite3"
			elsif format == "Access"
				format = "access"
			}else
				msgbox(gtext("Warning"), gtext("Format hasnt been supported yet. Sorry."), "warning")
				return false
			}

			# Create helper objects.
			require_once("knjphpframework/knjdb/drivers/" . format . "/class_knjdb_" . format . "_rows.php")
			require_once("knjphpframework/knjdb/drivers/" . format . "/class_knjdb_" . format . "_tables.php")
			require_once("knjphpframework/knjdb/drivers/" . format . "/class_knjdb_" . format . "_indexes.php")
			ob1 = "knjdb_" . format . "_rows"
			ob2 = "knjdb_" . format . "_tables"
			ob3 = "knjdb_" . format . "_indexes"
			ob_rows = new ob1(@dbconn)
			ob_tables = new ob2(@dbconn)
			ob_indexes = new ob3(@dbconn)

			# Validate if we should open and read a gz-file or a plaintext sql-file.
			if self.glade.get_widget("chkGZIP").active
				if strtolower(substr(filename, -7, 7)) != ".sql.gz"
					filename .= ".sql.gz"
				}

				mode = "gz"
				fp = gzopen(filename, "w9")
			}else
				if strtolower(substr(filename, -4, 4)) != ".sql"
					filename .= ".sql"
				}

				mode = "plain"
				fp = fopen(filename, "w")
			}

			if self.glade.get_widget("chkData").active
				data = true
			}

			if self.glade.get_widget("chkStructure").active
				struc = true
			}

			if self.cinserts.active
				cins = true
			}


			# Read the tables from the database.
			win_status.SetStatus(0, gtext("Counting..."), true)
			tables = @dbconn.tables().getTables()

			# Validating which tables should be backed up.
			values = treeview_getSelection(@tv_tables)
			foreach(values AS value)
				tables_back[value[0]] = true
			}

			# Counting how many SQL-lines should be wrote as "points" (to make a status of the operation).
			count_points = 0
			countt_points = count(tables)
			foreach(tables AS tha_table)
				if tables_back[tha_table.get("name")]
					win_status.SetStatus(0, gtext("Counting") . " (" . tha_table.get("name") . ")...", true)

					f_cd = query("SELECT COUNT(*) AS count FROM " . tha_table.get("name"))
					d_cd = f_cd.fetch()

					countt_points += d_cd['count']
				}
			}

			# Backup of the database-structure (tables etc.)
			win_status.SetStatus(0, gtext("Executing backup") . " (0/" . count_points . ")", true)
			if struc == true
				foreach(tables AS tha_table)
					if tables_back[tha_table.get("name")]
						# Making SQL for the structure.
						columns = tha_table.getColumns()
						indexes = tha_table.getIndexes()

						colarr = array()
						foreach(columns AS col)
							colarr[] = col.data
						}

						sql .= ob_tables.createTable(tha_table.get("name"), colarr, array("returnsql" => true)) . "\n"

						if indexes
							foreach(indexes AS index)
								sql .= ob_indexes.addIndex(tha_table, index.getColumns(), null, array("returnsql" => true)) . "\n"
							}
						}

						# Flushing SQL to the file.
						@BackupFlush(fp, mode, sql)

						# Updating status-window.
						count_points++
						win_status.SetStatus(count_points / countt_points, gtext("Executing backup") . " (" . count_points . "/" . countt_points . ")")
					}
				}
			}

			# Backup of the data (inserts).
			if data == true
				foreach(tables AS tha_table)
					if tables_back[tha_table.get("name")]
						columns = tha_table.getColumns()
						win_status.SetStatus(perc, gtext("Executing backup") . " (" . count_points . "/" . countt_points . ") (Querying " . tha_table.get("name") . "...).", true)

						f_gd = query_unbuffered("SELECT * FROM " . tha_table.get("name"))
						while(d_gd = f_gd.fetch())
							sql .= ob_rows.getArrInsertSQL(tha_table.get("name"), d_gd) . "\n"

							@BackupFlush(fp, mode, sql)
							count_points++
							perc = count_points / countt_points
							win_status.SetStatus(perc, gtext("Executing backup") . " (" . count_points . "/" . countt_points . ") (Reading " . tha_table.get("name") . ").")
						}
					}
				}
			}

			# Flushing rest of data (there shouldnt be any - just to be safe).
			@BackupFlush(fp, mode, sql)

			# Closing file-pointer.
			if mode == "gz"
				gzclose(fp)
			elsif mode == "plain"
				fclose(fp)
			}

			# Closing status-window and reset the operation.
			win_status.CloseWindow()
			msgbox(gtext("Information"), gtext("The backup execution has ended, and the backup-file has been written."), "info")
			@CloseWindow()
		}

		# Flush stuff to the file.
		def BackupFlush(fp, mode, &sql)
			if mode == "gz"
				gzwrite(fp, sql)
			elsif mode == "plain"
				fwrite(fp, sql)
			}

			sql = ""
		}

		# Closes the window.
		def CloseWindow
			@window.destroy()
		}
	}
?>