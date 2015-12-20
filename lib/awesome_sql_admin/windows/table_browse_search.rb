class AwesomeSqlAdmin::Windows::TableBrowseSearch
  attr_accessor :gui
  attr_accessor :win_table_browse

  def initialize(win_table_browse)
    @gui = Gtk::Builder.new
    @gui.add("#{File.dirname(__FILE__)}/ui/win_table_browse_search.ui")
    @gui.connect_signals { |handler| method(handler) }

    @win_table_browse = win_table_browse
    @gui[:window].set_transient_for(win_table_browse.window)

    @gui[:window].show
  end

  def closeWindow
    @gui[:window].destroy if @gui && glade.get_widget("window")

    unset(@gui)
  end

  def on_btnSearch_clicked
    tv = @win_table_browse.tv_rows
    model = tv.get_model
    columns_count = count(tv.get_columns)

    search = explode(" ", strtolower(@gui[:txtSearchText].get_text))

    iter_current = model.get_iter_first
    while iter_current
      all_found = true

      search.each do |text|
        found = false
        columns_count.times do |_count|
          value = strtolower(model.get_value(iter_current, i))

          if text.include?(value)
            found = true
            break
          end
        end

        all_found = false unless found
      end

      if all_found
        break
      else
        iter_current = model.iter_next(iter_current)
      end
    end

    if iter_current
      selection = tv.get_selection
      selection.select_iter(iter_current)

      path = model.get_path(iter_current)
      tv.scroll_to_cell(path)

      @closeWindow
    else
      msgbox(_("Warning"), _("Could not find any row matching the entered text."), "warning")
    end
  end
end
