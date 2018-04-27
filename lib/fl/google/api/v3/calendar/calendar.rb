module Fl::Google::API::V3::Calendar
  # Class to manage calendars.

  class Calendar < Fl::Google::API::V3::Calendar::Base
    GET_CALENDAR_PATH_TEMPLATE = '/calendars/%s'

    # Initializer.
    #
    # @param config A hash containing configuration options.

    def initialize(config = {})
      super(config)
    end

    # Get calendar data.
    #
    # @param calendar_id The Google calendar identifier; a @c nil value implies the 'primary' calendar.
    # @param opts A Hash containing optional arguments. Currently no arguments are supported.
    #
    # @return Returns a response object, or nil for failures before the get call is made.
    #  The response object could contain a failure status.

    def get_calendar(calendar_id = nil, opts = {})
      query = {}
      get(get_calendar_path(calendar_id, opts), query)
    end

    private

    def get_calendar_path(calendar_id, opts = {})
      cal_id = calendar_id || 'primary'
      sprintf(GET_CALENDAR_PATH_TEMPLATE, cal_id)
    end
  end
end
