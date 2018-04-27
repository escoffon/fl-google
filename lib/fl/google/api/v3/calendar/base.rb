module Fl::Google::API::V3::Calendar
  # Base class for Google Calendar API (v3) objects using the Floopstreet YouTube developer key.

  class Base < Fl::Google::API::V3::Base
    ROOT_URL = 'https://www.googleapis.com/calendar/v3'

    # Initializer.
    # Adds the following configuration parameters and calls the superclass implementation.
    # - :root_url 
    #
    # @param config A hash containing configuration options.

    def initialize(config = {})
      c = config.dup
      c[:root_url] = ROOT_URL

      super(c)
    end

    protected

    SYNC_KEYS = [ :iCalUID, :orderBy, :privateExtendedProperty, :q, :sharedExtendedProperty, :timeMin,
                  :timeMax, :updatedMin ]

    # Filter and otherwise process a query string.
    # This method removes the following keys if @c :syncToken or @a :pageToken are present:
    # @c :iCalUID, @c :orderBy, @c :privateExtendedProperty, @c :q, @c :sharedExtendedProperty, @c :timeMin,
    # @c :timeMax, and @c :updatedMin
    #
    # This method is called by the method that generates the query string.
    # The default implementation simply returns @a query: no processing is done.
    #
    # @param query A hash containing the query parameters.
    #
    # @return Returns a hash containing the processed values.

    def filter_query(query = {})
      return query unless query.has_key?(:syncToken) || query.has_key?('syncToken') \
      		|| query.has_key?(:pageToken) || query.has_key?('pageToken')
      
      nq = {}
      query.each do |k, v|
        sk = k.to_sym
        nq[sk] = v unless SYNC_KEYS.include?(sk)
      end

      nq
    end
  end
end
