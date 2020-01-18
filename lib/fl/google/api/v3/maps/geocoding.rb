require 'uri'

require 'fl/google/api/v3'
require 'fl/google/api/maps'

module Fl::Google::API::V3::Maps
  # Google Maps geocoding API

  class Geocoding < Fl::Google::API::V3::Base
    # @!visibility private
    ROOT_URL = 'https://maps.googleapis.com/maps/api/geocode'

    # The environment variable that stores the API key to use, if one is not provided in the initializer.

    GOOGLE_MAPS_API_KEY_VARIABLE = 'GOOGLE_MAPS_API_KEY'

    # Initializer.
    # Adds the following configuration parameters and calls the superclass implementation.
    # - :root_url The root of the request URL.
    #
    # @param config [Hash] A hash containing configuration options.
    # @option config [String] :api_key The API key. If this property is not present, the initializer
    #  attempts to read it from the environment variable {GOOGLE_MAPS_API_KEY_VARIABLE}.

    def initialize(config = {})
      c = config.dup
      c[:root_url] = ROOT_URL

      unless c[:api_key]
        c[:api_key] = ENV[GOOGLE_MAPS_API_KEY_VARIABLE] if ENV[GOOGLE_MAPS_API_KEY_VARIABLE]
      end

      super(c)
    end

    # Get geolocation data for a given address.
    #
    # @param address A string containing the address.
    #
    # @return Returns a hash containing geolocation information.

    def geocode(address)
      q = { address: URI::encode(address) }
      q[:key] = @config[:api_key] if @config.has_key?(:api_key)

      res = get('/json', q)
      JSON::parse(res.body)
    end
  end
end
