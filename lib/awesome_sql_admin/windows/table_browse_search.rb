
	class WinTableBrowseSearch
		attr_accessor :glade
		attr_accessor :win_table_browse

		def initialize(WinTableBrowse win_table_browse)
			@glade = new GladeXML("glades/win_table_browse_search.glade")
			@glade.signal_autoconnect_instance(self)

			@win_table_browse = win_table_browse
			@glade.get_widget("window").set_transient_for(win_table_browse.window)

			@glade.get_widget("window").show()
		}

		def closeWindow
			if @glade && self.glade.get_widget("window")
				@glade.get_widget("window").destroy()
			}

			unset(@glade)
		}

		def on_btnSearch_clicked
			tv = @win_table_browse.tv_rows
			model = tv.get_model()
			columns_count = count(tv.get_columns())

			search = explode(" ", strtolower(@glade.get_widget("txtSearchText").get_text()))

			iter_current = model.get_iter_first()
			while(iter_current)
				all_found = true

				foreach(search AS text)
					found = false
					for(i = 0; i < columns_count; i++)
						value = strtolower(model.get_value(iter_current, i))

						if strpos(value, text) !== false
							found = true
							break
						}
					}

					if !found
						all_found = false
					}
				}

				if all_found
					break
				}else
					iter_current = model.iter_next(iter_current)
				}
			}

			if iter_current
				selection = tv.get_selection()
				selection.select_iter(iter_current)

				path = model.get_path(iter_current)
				tv.scroll_to_cell(path)

				@closeWindow()
			}else
				msgbox(gtext("Warning"), gtext("Could not find any row matching the entered text."), "warning")
			}
		}
	}
?>