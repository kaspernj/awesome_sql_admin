
	/**
	 * This class shows and controls status-windows, which can be used by other classes. E.g. when backing up a database
	 * a window with a statusbar will show.
	*/
	class WinStatus
		attr_accessor :window
		attr_accessor :progress
		attr_accessor :label
		attr_accessor :idle_id

		# The constructor. It builds the window.
		def initialize
			# Create window.
			@window = new GtkWindow()
			@window.set_title("Status")
			@window.set_resizable(false)
			@window.set_position(GTK_WIN_POS_CENTER)
			@window.connect("destroy", array(self, "CloseWindow"))
			@window.set_size_request(500, -1)
			@window.set_border_width(3)
			@window.set_modal(true)

			# Create progressbar.
			adj = new GtkAdjustment(0.5, 100.0, 200.0, 0.0, 0.0, 0.0)
			@progress = new GtkProgressBar(adj)
			@@progress.set_percentage(0)

			# Create status-label.
			@label = new GtkLabel("Status: Waiting.")
			@label.set_alignment(0, 0.5)

			# Attach to window.
			box = new GtkVBox()
			box.add(@label)
			box.add(@progress)

			@window.add(box)
			@window.show_all()

			# Create idle-stuff to update the window.
			# @idle_id = Gtk::idle_add("updwin")
		}

		# Destroys the window and free's resources.
		def CloseWindow
			# Gtk::idle_remove(@idle_id)
			@window.destroy()
		}

		# Updates the status-text and progress-bar.
		def SetStatus(perc, text, doupd = false)
			/** NOTE:
			 * These two lines optimized the executing of a backup dramaticly. The reason for this, is that it takes time
			 * every time that the status has to be updated. Actually with a database with 10.000 rows, it will be updated
			 * 10.000 times. But since the human eye can only see about hundred, there is no reason to show more.
			 * And that is what is done here by comparing two variables.
			*/

			perc = round(perc, 3)
			if perc != @perc || doupd
				@label.set_text("Status: " . text)

				@perc = perc
				@@progress.set_percentage(perc)
				updwin()
			}

			unset(perc)
			unset(text)
			unset(doupd)
		}
	}
?>