
	# *This class controls the window which is able to browse and manipulate with data within a given table. */
	class WinTableBrowse
		attr_accessor :dbconn
		attr_accessor :glade
		public window
		public tv_rows
		public updated
		public dbpage
		public table

		# ** The constructor of WinTableBrowse.
		 *
		 * @param DBPage dbpage The dbpage which the table should be browsed from.
		 * @param string table The table which should be browsed.
		*/
		def initialize(dbpage, table)
			@dbpage = dbpage
			@dbconn = @dbpage.dbconn
			@table = table

			@glade = new GladeXML("glades/win_table_browse.glade")
			@glade.signal_autoconnect_instance(self)

			@window = @glade.get_widget("window")
			winsetting = new GtkSettingsWindow(@window, "win_table_browse")

			global win_main
			@window.set_transient_for(win_main.window)

			if !table
				msgbox(gtext("Error"), gtext("No table is currently selected."), "warning")
				@CloseWindow()
				return null
			}

			# Read columns.
			@columns = @dbconn.getTable(self.table).getColumns()
			if !self.columns
				msgbox(gtext("Error"), gtext("No columns found for this table."), "warning")
				@CloseWindow()
				return null
			}

			# Add columns to the treeview.
			foreach(@columns AS column)
				tvcolumns[] = column.get("name")
			}
			@tv_rows = @glade.get_widget("tvRows")
			treeview_addColumn(@tv_rows, tvcolumns)

			@UpdateClist()
			@window.show_all()
		}

		# *Deletes all rows in the table (not a truncate, and therefore does not reset any auto-increment-values). */
		def DelAllClicked
			if msgbox(gtext("Question"), gtext("Do you want to delete all the rows in the table: '") . @table . "'?", "yesno") == "yes"
				@dbconn.delete(self.table)
				@UpdateClist()
				@updated = true
			}
		}

		# *Asks and then truncates the table. */
		def EmptyClicked
			if msgbox(gtext("Question"), sprintf(gtext("Do you want to truncate the table: \"%s\"?"), @table), "yesno") == "yes"
				if !self.dbconn.TruncateTable(self.table)
					msgbox(gtext("Warning"), sprintf(gtext("Could not truncate the table.\n\n%s"), query_error()), "warning")
				}

				@UpdateClist()
				@updated = true
			}
		}

		# *Deletes the selected row from the table. */
		def DeleteSelectedClicked
			# Get required data.
			selected = treeview_getSelection(@tv_rows)

			# Tjeck for possible failure and interrupt.
			if !selected
				msgbox(gtext("Warning"), gtext("You have not selected any row."), "warning")
				return false
			}

			# Think about what to tell the database.
			columns = @dbconn.getTable(self.table).getColumns()
			count = 0
			foreach(@columns AS value)
				columns_del[value.get("name")] = selected[count]
				count++
			}

			try
				@dbconn.delete(self.table, columns_del)
			}catch(Exception e)
				msgbox(gtext("Error"), sprintf(gtext("The selected row could not be deleted: %s"), e.getMessage()), "warning")
			}

			# Update clist and mark as updated for closing procedures.
			selection = @tv_rows.get_selection()
			list(model, iter) = selection.get_selected()
			model.remove(iter)
			@updated = true
		}

		# *Reloads the rows-treeview. */
		def UpdateClist
			try
				status_countt = @dbconn.getTable(self.table).countRows()
				status_count = 0

				require_once("knjphpframework/win_status.php")
				win_status = new WinStatus(array("window_parent" => @window))
				win_status.SetStatus(0, sprintf(gtext("Reading table rows %s."), "(" . status_count . "/" . status_countt . ")"), true)

				@tv_rows.get_model().clear()
				f_gc = @dbconn.select(self.table)
				while(d_gc = f_gc.fetch())
					array = array()
					status_count++
					count = 0
					foreach(@columns AS column)
						array[] = string_oneline(d_gc[column.get("name")])
						count++
					}

					@tv_rows.get_model().append(array); # Insert into the clist.
					win_status.SetStatus(status_count / status_countt, sprintf(gtext("Reading table rows %s."), "(" . status_count . "/" . status_countt . ")"))
				}
			}catch(Exception e)
				msgbox(gtext("Warning"), sprintf(gtext("An error occurred while trying to reload the rows-treeview: %s"), e.getMessage()), "warning")
			}

			if win_status
				win_status.CloseWindow()
			}
		}

		# *Handels the event, when the insert-row-button is clicked. It opens the insert-row-window. */
		def InsertIntoClicked
			require_once("gui/win_table_browse_insert.php")
			win_table_browse_insert = new WinTableBrowseInsert(self)
		}

		# *Closes and destroys the window. */
		def CloseWindow
			if @updated == true
				@dbpage.TablesUpdate()
			}

			@window.destroy()
			unset(@glade, @window, @dbconn, @dbpage, @updated, @table, @tv_rows)
		}

		def on_btnSearch_clicked
			require_once("gui/win_table_browse_search.php")
			win_table_browse_search = new WinTableBrowseSearch(self)
		}
	}
?>