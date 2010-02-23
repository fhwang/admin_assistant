class AdminAssistant
  # Copied (and then streamlined) from Rails 2.3.5 in an effort to provide 
  # consistent functionality all the way back to Rails 2.1.0
  class DateTimeRangeEndPointSelector
    include ActionView::Helpers::TagHelper

    DEFAULT_PREFIX = 'date'.freeze unless const_defined?('DEFAULT_PREFIX')
    POSITION = {
      :year => 1, :month => 2, :day => 3, :hour => 4, :minute => 5, :second => 6
    }.freeze unless const_defined?('POSITION')

    def initialize(datetime, options = {}, html_options = {})
      @options      = options.dup
      @html_options = html_options.dup
      @datetime     = datetime
    end

    def select_datetime
      # TODO: Remove tag conditional
      # Ideally we could just join select_date and select_date for the tag case
      if @options[:tag] && @options[:ignore_date]
        select_time
      elsif @options[:tag]
        order = date_order.dup
        order -= [:hour, :minute, :second]

        @options[:discard_year]   ||= true unless order.include?(:year)
        @options[:discard_month]  ||= true unless order.include?(:month)
        @options[:discard_day]    ||= true if @options[:discard_month] || !order.include?(:day)
        @options[:discard_minute] ||= true if @options[:discard_hour]
        @options[:discard_second] ||= true unless @options[:include_seconds] && !@options[:discard_minute]

        # If the day is hidden and the month is visible, the day should be set to the 1st so all month choices are
        # valid (otherwise it could be 31 and february wouldn't be a valid date)
        if @datetime && @options[:discard_day] && !@options[:discard_month]
          @datetime = @datetime.change(:day => 1)
        end

        [:day, :month, :year].each { |o| order.unshift(o) unless order.include?(o) }
        order += [:hour, :minute, :second] unless @options[:discard_hour]

        build_selects_from_types(order)
      else
        "#{select_date}#{@options[:datetime_separator]}#{select_time}"
      end
    end

    def select_date
      order = date_order.dup

      # TODO: Remove tag conditional
      if @options[:tag]
        @options[:discard_hour]     = true
        @options[:discard_minute]   = true
        @options[:discard_second]   = true

        @options[:discard_year]   ||= true unless order.include?(:year)
        @options[:discard_month]  ||= true unless order.include?(:month)
        @options[:discard_day]    ||= true if @options[:discard_month] || !order.include?(:day)

        # If the day is hidden and the month is visible, the day should be set to the 1st so all month choices are
        # valid (otherwise it could be 31 and february wouldn't be a valid date)
        if @datetime && @options[:discard_day] && !@options[:discard_month]
          @datetime = @datetime.change(:day => 1)
        end
      end

      [:day, :month, :year].each { |o| order.unshift(o) unless order.include?(o) }

      build_selects_from_types(order)
    end

    def select_time
      order = []

      # TODO: Remove tag conditional
      if @options[:tag]
        @options[:discard_month]    = true
        @options[:discard_year]     = true
        @options[:discard_day]      = true
        @options[:discard_second] ||= true unless @options[:include_seconds]

        order += [:year, :month, :day] unless @options[:ignore_date]
      end

      order += [:hour, :minute]
      order << :second if @options[:include_seconds]

      build_selects_from_types(order)
    end

    def select_second
      if @options[:use_hidden] || @options[:discard_second]
        build_hidden(:second, sec) if @options[:include_seconds]
      else
        build_options_and_select(:second, sec)
      end
    end

    def select_minute
      if @options[:use_hidden] || @options[:discard_minute]
        build_hidden(:minute, min)
      else
        build_options_and_select(:minute, min, :step => @options[:minute_step])
      end
    end

    def select_hour
      if @options[:use_hidden] || @options[:discard_hour]
        build_hidden(:hour, hour)
      else
        build_options_and_select(:hour, hour, :end => 23)
      end
    end

    def select_day
      if @options[:use_hidden] || @options[:discard_day]
        build_hidden(:day, day)
      else
        build_options_and_select(:day, day, :start => 1, :end => 31, :leading_zeros => false)
      end
    end

    def select_month
      if @options[:use_hidden] || @options[:discard_month]
        build_hidden(:month, month)
      else
        month_options = []
        1.upto(12) do |month_number|
          options = { :value => month_number }
          options[:selected] = "selected" if month == month_number
          month_options << content_tag(:option, month_name(month_number), options) + "\n"
        end
        build_select(:month, month_options.join)
      end
    end

    def select_year
      if !@datetime || @datetime == 0
        val = ''
        middle_year = Date.today.year
      else
        val = middle_year = year
      end

      if @options[:use_hidden] || @options[:discard_year]
        build_hidden(:year, val)
      else
        options                 = {}
        options[:start]         = @options[:start_year] || middle_year - 5
        options[:end]           = @options[:end_year] || middle_year + 5
        options[:step]          = options[:start] < options[:end] ? 1 : -1
        options[:leading_zeros] = false

        build_options_and_select(:year, val, options)
      end
    end

    private
      %w( sec min hour day month year ).each do |method|
        define_method(method) do
          @datetime.kind_of?(Fixnum) ? @datetime : @datetime.send(method) if @datetime
        end
      end

      # Returns translated month names, but also ensures that a custom month
      # name array has a leading nil element
      def month_names
        month_names = @options[:use_month_names] || translated_month_names
        month_names.unshift(nil) if month_names.size < 13
        month_names
      end

      # Returns translated month names
      #  => [nil, "January", "February", "March",
      #           "April", "May", "June", "July",
      #           "August", "September", "October",
      #           "November", "December"]
      #
      # If :use_short_month option is set
      #  => [nil, "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      #           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
      def translated_month_names
        if @options[:use_short_month]
          [nil, "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep",
           "Oct", "Nov", "Dec"]
        else
          [nil, "January", "February", "March", "April", "May", "June", "July",
           "August", "September", "October", "November", "December"]
        end
      end

      # Lookup month name for number
      #  month_name(1) => "January"
      #
      # If :use_month_numbers option is passed
      #  month_name(1) => 1
      #
      # If :add_month_numbers option is passed
      #  month_name(1) => "1 - January"
      def month_name(number)
        if @options[:use_month_numbers]
          number
        elsif @options[:add_month_numbers]
          "#{number} - #{month_names[number]}"
        else
          month_names[number]
        end
      end

      def date_order
        @options[:order] || translated_date_order
      end

      def translated_date_order
        [:year, :month, :day]
      end

      # Build full select tag from date type and options
      def build_options_and_select(type, selected, options = {})
        build_select(type, build_options(selected, options))
      end

      # Build select option html from date value and options
      #  build_options(15, :start => 1, :end => 31)
      #  => "<option value="1">1</option>
      #      <option value=\"2\">2</option>
      #      <option value=\"3\">3</option>..."
      def build_options(selected, options = {})
        start         = options.delete(:start) || 0
        stop          = options.delete(:end) || 59
        step          = options.delete(:step) || 1
        leading_zeros = options.delete(:leading_zeros).nil? ? true : false

        select_options = []
        start.step(stop, step) do |i|
          value = leading_zeros ? sprintf("%02d", i) : i
          tag_options = { :value => value }
          tag_options[:selected] = "selected" if selected == i
          select_options << content_tag(:option, value, tag_options)
        end
        select_options.join("\n") + "\n"
      end

      # Builds select tag from date type and html select options
      #  build_select(:month, "<option value="1">January</option>...")
      #  => "<select id="post_written_on_2i" name="post[written_on(2i)]">
      #        <option value="1">January</option>...
      #      </select>"
      def build_select(type, select_options_as_html)
        select_options = {
          :id => input_id_from_type(type),
          :name => input_name_from_type(type)
        }.merge(@html_options)
        select_options.merge!(:disabled => 'disabled') if @options[:disabled]

        select_html = "\n"
        select_html << content_tag(:option, '', :value => '') + "\n" if @options[:include_blank]
        select_html << prompt_option_tag(type, @options[:prompt]) + "\n" if @options[:prompt]
        select_html << select_options_as_html.to_s

        content_tag(:select, select_html, select_options) + "\n"
      end

      # Builds a prompt option tag with supplied options or from default options
      #  prompt_option_tag(:month, :prompt => 'Select month')
      #  => "<option value="">Select month</option>"
      def prompt_option_tag(type, options)
        default_options = {:year => false, :month => false, :day => false, :hour => false, :minute => false, :second => false}

        case options
        when Hash
          prompt = default_options.merge(options)[type.to_sym]
        when String
          prompt = options
        else
          prompt = I18n.translate(('datetime.prompts.' + type.to_s).to_sym, :locale => @options[:locale])
        end

        prompt ? content_tag(:option, prompt, :value => '') : ''
      end

      # Builds hidden input tag for date part and value
      #  build_hidden(:year, 2008)
      #  => "<input id="post_written_on_1i" name="post[written_on(1i)]" type="hidden" value="2008" />"
      def build_hidden(type, value)
        tag(:input, {
          :type => "hidden",
          :id => input_id_from_type(type),
          :name => input_name_from_type(type),
          :value => value
        }) + "\n"
      end

      # Returns the name attribute for the input tag
      #  => post[written_on(1i)]
      def input_name_from_type(type)
        prefix = @options[:prefix] || DEFAULT_PREFIX
        prefix += "[#{@options[:index]}]" if @options.has_key?(:index)

        field_name = @options[:field_name] || type
        if @options[:include_position]
          field_name += "(#{POSITION[type]}i)"
        end

        @options[:discard_type] ? prefix : "#{prefix}[#{field_name}]"
      end

      # Returns the id attribute for the input tag
      #  => "post_written_on_1i"
      def input_id_from_type(type)
        input_name_from_type(type).gsub(/([\[\(])|(\]\[)/, '_').gsub(/[\]\)]/, '')
      end

      # Given an ordering of datetime components, create the selection HTML
      # and join them with their appropriate separators.
      def build_selects_from_types(order)
        select = ''
        order.reverse.each do |type|
          separator = separator(type) unless type == order.first # don't add on last field
          select.insert(0, separator.to_s + send("select_#{type}").to_s)
        end
        select
      end

      # Returns the separator for a given datetime component
      def separator(type)
        case type
          when :month, :day
            @options[:date_separator]
          when :hour
            (@options[:discard_year] && @options[:discard_day]) ? "" : @options[:datetime_separator]
          when :minute
            @options[:time_separator]
          when :second
            @options[:include_seconds] ? @options[:time_separator] : ""
        end
      end
  end
end
