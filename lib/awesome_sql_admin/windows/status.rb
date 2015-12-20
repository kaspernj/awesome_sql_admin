class AwesomeSqlAdmin::Windows::Status
  attr_accessor :window
  attr_accessor :progress
  attr_accessor :label
  attr_accessor :idle_id

  # The constructor. It builds the window.
  def initialize
    # Create window.
    @window = GtkWindow.new()
    @window.set_title("Status")
    @window.set_resizable(false)
    @window.set_position(GTK_WIN_POS_CENTER)
    @window.connect("destroy", [self, "CloseWindow"))
    @window.set_size_request(500, -1)
    @window.set_border_width(3)
    @window.set_modal(true)

    # Create progressbar.
    adj = GtkAdjustment.new(0.5, 100.0, 200.0, 0.0, 0.0, 0.0)
    @progress = GtkProgressBar.new(adj)
    @@progress.set_percentage(0)

    # Create status-label.
    @label = GtkLabel.new("Status: Waiting.")
    @label.set_alignment(0, 0.5)

    # Attach to window.
    box = GtkVBox.new()
    box.add(@label)
    box.add(@progress)

    @window.add(box)
    @window.show_all()

    # Create idle-stuff to update the window.
    # @idle_id = Gtk::idle_add("updwin")
  end

  # Destroys the window and free's resources.
  def CloseWindow
    # Gtk::idle_remove(@idle_id)
    @window.destroy()
  end

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
    end
  end
end
