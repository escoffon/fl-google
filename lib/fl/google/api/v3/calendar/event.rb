module Fl::Google::API::V3::Calendar
  # Class to manage calendar events.

  class Event < Fl::Google::API::V3::Calendar::Base
    LIST_EVENTS_PATH_TEMPLATE = '/calendars/%s/events'
    CREATE_EVENT_PATH_TEMPLATE = '/calendars/%s/events'
    UPDATE_EVENT_PATH_TEMPLATE = '/calendars/%s/events/%s'
    PATCH_EVENT_PATH_TEMPLATE = '/calendars/%s/events/%s'
    DELETE_EVENT_PATH_TEMPLATE = '/calendars/%s/events/%s'
    GET_EVENT_PATH_TEMPLATE = '/calendars/%s/events/%s'
    WATCH_EVENTS_PATH_TEMPLATE = '/calendars/%s/events/watch'

    UPDATE_PROPERTIES = [ :start, :end, :summary, :description, :location, :status,
                          :visibility, :attendees ]

    # Initializer.
    #
    # @param config A hash containing configuration options.

    def initialize(config = {})
      super(config)
    end

    # List events in a calendar.
    # This method makes a request to list the events in a calendar; the return value is a response object
    # whose body contains the event list.
    #
    # @param calendar_id The calendar identifier. The default value is @c primary (the name of the default,
    #  primary, Google calendar).
    # @param opts A Hash containing optional arguments, which will be appended to the request URL in the
    #  query string. The Google Calendar documentation contains the description of these optional
    #  parameters, but a few are interesting:
    #  - :pageToken is used to retrieve paginated data.
    #  - :syncToken is used to perform incremental sync requests.
    #
    # @return Returns a response object, or nil for failures before the create call is made.
    #  The response object could contain a failure status.

    def list_events(calendar_id = nil, opts = {})
      query = {}
      opts.each do |k, v|
        sk = k.to_sym
        query[sk] = v
      end

      get(list_events_path(calendar_id, opts), query)
    end

    # Create an event.
    # This method creates an event with the same properties as @a event, and possibly from additional
    # data from @a opts.
    #
    # By default, the event is located in the 'default" calendar, but this can be changed in @a opts.
    #
    # @param event The instance of Fl::Db::Assets::CalendarEvent to use. The method extracts the
    #  following Google Event properties from the event attributes:
    #   - :start and :end from :start_datetime and :end_datetime, respectively
    #   - :summary from :title.
    #   - :description from the text-only nodes of :note.
    #   - :location from :location.
    #   - :status from :completion_state.
    #  Alternatively, @a event is a Hash containing the Google Event properties directly, and is used
    #  as is in the Google API call.
    # @param opts A Hash containing optional arguments. The following key/value pairs are processed:
    #  - :calendar The identifier for the Google calendar where the event is created.
    #    Use 'primary' (which is the default value) for the default/primary calendar.
    #  - :visibility Is the Google Calendar visibility level: :default, :private, or :public.
    #    The default value is :default.
    #  - :attendees This can take two types of values. If an Array, it contains Fl::Db::Core::User
    #    or Fl::Db::Core::Group objects that list the individuals who will be placed in the :attendees
    #    parameters. Groups are expanded to users, and only users with email addresses are added to
    #    the list. If the value is the symbol :from_visibility, the list of attendees is generated
    #    from the event's visibility settings. If visibility is :private or :public, no attendees
    #    are listed, and the visibility is set to :private or :public, respectively.
    #    If visibility is :group or :friends, the attendees list is generated from the members of
    #    groups which have been granted access, and the visibility is set to :private.
    #  - :sendNotifications A boolean value to control notification by the Google API; this value,
    #    if present, is tagged as the @c sendNotifications optional query parameter.
    #
    # @return Returns a response object, or nil for failures before the create call is made.
    #  The response object could contain a failure status.

    def create_event(event, opts = {})
      query = {}
      if opts.has_key?(:sendNotifications)
        query[:sendNotifications] = (opts[:sendNotifications]) ? 'True' : 'False'
      end

      if event.is_a?(Hash)
        params = event
      else
        params = {
          :summary => event.title,
          :start => date_parameter(event.start_datetime, event.timezone),
          :end => date_parameter(event.end_datetime, event.timezone)
        }

        if event.note
          params[:description] = html_text_only(nil, event.note)
        end

        params[:location] = event.location if event.location

        case event.completion_state
        when Fl::Db::Assets::CalendarEvent::TENTATIVE
          params[:status] = 'tentative'
        when Fl::Db::Assets::CalendarEvent::CONFIRMED
          params[:status] = 'confirmed'
        when Fl::Db::Assets::CalendarEvent::ABANDONED
          params[:status] = 'cancelled'
        end
      end

      params[:visibility] = opts[:visibility] if opts.has_key?(:visibility)

      if opts.has_key?(:attendees)
        case opts[:attendees]
        when :from_visibility
          v, a = attendees_from_visibility(event)
          params[:visibility] = v
          params[:attendees] = a
        else
          params[:attendees] = opts[:attendees]
        end
      end

      response = post(create_event_path(event, opts), params, query)

      if response.is_a?(Net::HTTPOK)
        rjson = ActiveSupport::JSON.decode(response.body)
        gid = rjson['id']

        event.google_identifier = gid
        event.google_access_key = self.access_key
        event.save
      end

      response
    end

    # Update an event.
    # This method updates an event with the same properties as @a event, and possibly from additional
    # data from @a opts.
    #
    # By default, the event is located in the 'default" calendar, but this can be changed in @a opts.
    #
    # @param event The instance of Fl::Db::Assets::CalendarEvent to use. The method extracts the
    #  following Google Event properties from the event attributes:
    #   - :start and :end from :start_datetime and :end_datetime, respectively
    #   - :summary from :title.
    #   - :description from the text-only nodes of :note.
    #   - :location from :location.
    #   - :status from :completion_state.
    #  Alternatively, @a event is a Hash containing the Google Event properties directly, and is used
    #  as is in the Google API call. In this case, @a opts must contain the :event_id key, so that the
    #  API knows which event to update. Also, if @a event contains the :visibiity or :attendees keys,
    #  the values in @a opts (if any) are ignored.
    # @param opts A Hash containing optional arguments. The following key/value pairs are processed:
    #  - :event_id If @a event is a Hash, this is the Google Calendar identifier for the event.
    #    If @a event is a CalendarEvent object, this option is ignord.
    #  - :properties An array containing the names of properties to be updated; if not present or
    #    @c nil, all relevant properties in the event are updated.
    #    If @a event is a Hash, this option is ignord.
    #  - :calendar The identifier for the Google calendar where the event is created.
    #    Use 'primary' (which is the default value) for the default/primary calendar.
    #  - :visibility Is the Google Calendar visibility level: :default, :private, or :public.
    #    The default value is :default.
    #    If @a event is a Hash, this option is ignord.
    #  - :attendees This can take two types of values. If an Array, it contains Fl::Db::Core::User
    #    or Fl::Db::Core::Group objects that list the individuals who will be placed in the :attendees
    #    parameters. Groups are expanded to users, and only users with email addresses are added to
    #    the list. If the value is the symbol :from_visibility, the list of attendees is generated
    #    from the event's visibility settings. If visibility is :private or :public, no attendees
    #    are listed, and the visibility is set to :private or :public, respectively.
    #    If visibility is :group or :friends, the attendees list is generated from the members of
    #    groups which have been granted access, and the visibility is set to :private.
    #    If @a event is a Hash, this option is ignord.
    #  - :sendNotifications A boolean value to control notification by the Google API; this value,
    #    if present, is tagged as the @c sendNotifications optional query parameter.
    #
    # @return Returns a response object, or nil for failures before the create call is made.
    #  The response object could contain a failure status.

    def update_event(event, opts = {})
      query = {}
      if opts.has_key?(:sendNotifications)
        query[:sendNotifications] = (opts[:sendNotifications]) ? 'True' : 'False'
      end

      if event.is_a?(Hash)
        raise "update_event: missing :event_id option for hash parameter" unless opts.has_key?(:event_id)
        event_id = opts[:event_id]
        params = event
      else
        event_id = event.google_identifier
        params = {}
        plist = ((opts.has_key?(:properties)) ? opts[:properties] : UPDATE_PROPERTIES).map { |l| l.to_sym }

        params[:summary] = event.title if plist.include?(:summary)
        params[:start] = date_parameter(event.start_datetime, event.timezone) if plist.include?(:start)
        params[:end] = date_parameter(event.end_datetime, event.timezone) if plist.include?(:end)

        if plist.include?(:description)
          params[:description] = html_text_only(nil, event.note)
        end

        params[:location] = event.location if plist.include?(:location)

        if plist.include?(:status)
          case event.completion_state
          when Fl::Db::Assets::CalendarEvent::TENTATIVE
            params[:status] = 'tentative'
          when Fl::Db::Assets::CalendarEvent::CONFIRMED
            params[:status] = 'confirmed'
          when Fl::Db::Assets::CalendarEvent::ABANDONED
            params[:status] = 'cancelled'
          end
        end

        params[:visibility] = opts[:visibility] if plist.include?(:visibility) && opts.has_key?(:visibility)

        if plist.include?(:attendees) && opts.has_key?(:attendees)
          case opts[:attendees]
          when :from_visibility
            v, a = attendees_from_visibility(event)
            params[:visibility] = v
            params[:attendees] = a
          else
            params[:attendees] = opts[:attendees]
          end
        end
      end

      if params.count > 0
        patch(patch_event_path(event_id, opts), params, query)
      else
        nil
      end
    end

    # Delete an event.
    #
    # @param event_id The Google event identifier.
    # @param opts A Hash containing optional arguments. The following key/value pairs are processed:
    #  - :calendar The identifier for the Google calendar where the event is created.
    #    Use 'primary' (which is the default value) for the default/primary calendar.
    #  - :sendNotifications A boolean value to control notification by the Google API; this value,
    #    if present, is tagged as the @c sendNotifications optional query parameter.
    #
    # @return Returns a response object, or nil for failures before the create call is made.
    #  The response object could contain a failure status.

    def delete_event(event_id, opts = {})
      query = {}
      if opts.has_key?(:sendNotifications)
        query[:sendNotifications] = (opts[:sendNotifications]) ? 'True' : 'False'
      end

      delete(delete_event_path(event_id, opts), query)
    end

    # Get event data.
    #
    # @param event_id The Google event identifier.
    # @param opts A Hash containing optional arguments. The following key/value pairs are processed:
    #  - :calendar The identifier for the Google calendar where the event is created.
    #    Use 'primary' (which is the default value) for the default/primary calendar.
    #
    # @return Returns a response object, or nil for failures before the get call is made.
    #  The response object could contain a failure status.

    def get_event(event_id, opts = {})
      query = {}
      get(get_event_path(event_id, opts), query)
    end

    # Start push notifications on a calendar.
    # This method makes a call to the @c watch API for events.
    #
    # @param calendar_id The calendar identifier. The default value is @c primary (the name of the default,
    #  primary, Google calendar).
    # @param params A Hash containing parameters for the request body. The following are documented by
    #  Google:
    #  - :id The channel identifier. If one is not provided, the method generates a UUID for it.
    #  - :token, :address, and :expiration are as described in the Google docuemtation. They are optional.
    #  - :address Is the URL to the callback in our server.
    #
    # @return Returns a response object, or nil for failures before the create call is made.
    #  The response object could contain a failure status.

    def start_notifications(calendar_id = nil, params = {})
      pars = { :id => SecureRandom.uuid, :type => 'web_hook' }.merge(params)
      post(watch_events_path(calendar_id, params), pars)
    end

    # Given an event, build a list of attendees based on its visibility settings.
    # If the event visibility is :private, returns visibility @c :private and an empty attendees list.
    # If the event visibility is :public, returns visibility @c :public and an empty attendees list.
    # If the event visibility is :group or :friends, returns visibility @c :private and a list of attendees.
    #
    # The list of attendees is generated as follows. Iterate over all users that have access to @a event;
    # for each user, if it is not the owner of the access key, and it has an email address, add an entry
    # to the attendees list. If users map to the same email address, the first user defines the bulk of the
    # entry, and subsequent users add their name to the display name.
    #
    # @return Returns a two-element array containing the value of the Google parameter :visibility, abd an
    #  array of attendee descriptors.

    def attendees_from_visibility(event)
      case event.visibility
      when :private
        [ 'private', [] ]
      when :public
        [ 'public', [] ]
      else
        owner = self.access_key.user
        eh = {}

        responses = {}
        event.responses.each do |r|
          responses[r.user_id] = r
        end

        # access_user already does not include the owner users, and the users are unique
        # But we generate only one assignee list per email

        event.access_users.each do |u|
          if (u.id != owner.id) && u.email && (u.email.length > 0)
            if eh[u.email]
              a = eh[u.email]
              a['displayName'] << ' / ' + u.user_name
            else
              eh[u.email] = make_attendee_data(u, responses)
            end
          end
        end

        # We need to add the event owner, unless it's the same as the key owner, or it has already been added

        u = event.owner
        if (u.id != owner.id) && u.email && (u.email.length > 0)
          eh[u.email] = make_attendee_data(u, responses)
        end

        [ 'private', eh.values ]
      end
    end

    private

    def date_parameter(datetime, tz)
      rv = {
        :timeZone => tz
      }

      if datetime.length == 8
        rv[:date] = sprintf('%s-%s-%s', datetime[0,4], datetime[4,2], datetime[6,2])
      else
        rv[:dateTime] = sprintf('%s-%s-%sT%02d:%02d:00',
                                datetime[0,4], datetime[4,2], datetime[6,2],
                                datetime[9,2].to_i, datetime[11,2].to_i)
      end

      rv
    end

    def list_events_path(calendar_id, opts = {})
      cal_id = 'primary' unless calendar_id.is_a?(String)
      sprintf(LIST_EVENTS_PATH_TEMPLATE, cal_id)
    end

    def create_event_path(event, opts = {})
      cal_id = opts[:calendar] || 'primary'
      sprintf(CREATE_EVENT_PATH_TEMPLATE, cal_id)
    end

    def update_event_path(event_id, opts = {})
      cal_id = opts[:calendar] || 'primary'
      sprintf(UPDATE_EVENT_PATH_TEMPLATE, cal_id, event_id)
    end

    def patch_event_path(event_id, opts = {})
      cal_id = opts[:calendar] || 'primary'
      sprintf(PATCH_EVENT_PATH_TEMPLATE, cal_id, event_id)
    end

    def delete_event_path(event_id, opts = {})
      cal_id = opts[:calendar] || 'primary'
      sprintf(DELETE_EVENT_PATH_TEMPLATE, cal_id, event_id)
    end

    def get_event_path(event_id, opts = {})
      cal_id = opts[:calendar] || 'primary'
      sprintf(GET_EVENT_PATH_TEMPLATE, cal_id, event_id)
    end

    def watch_events_path(calendar_id, opts = {})
      sprintf(WATCH_EVENTS_PATH_TEMPLATE, (calendar_id.is_a?(String)) ? calendar_id : 'primary')
    end

    def make_attendee_data(user, responses)
      a = {
        'displayName' => user.user_name,
        'email' => user.email
      }
      r = responses[user.id]
      if r
        a['responseStatus'] = case r.state
                              when :accepted
                                'accepted'
                              when :declined
                                'declined'
                              when :tentative
                                'tentative'
                              else
                                'needsAction'
                              end
        a['comment'] = html_text_only(nil, r.note)
      end

      a
    end

    # This belongs in a library (there is a copy of this in the Fl::Db::ModelFilters module)

    def html_text_only(ignored, value)
      if value.nil? || (value.length < 1)
        value
      else
        doc = Nokogiri::HTML(value)
        b = doc.search('body')
        s = ''
        b[0].search('text()').each { |e| s << e.serialize }

        # one last tweak: convert &amp;, &gt;, and &lt; back to the actual characters

        convert_character_entities(s)
      end
    end

    # same as above

    def convert_character_entities(t)
      t.gsub('&amp;', '&').gsub('&lt;', '<').gsub('&gt;', '>')
    end
  end
end
