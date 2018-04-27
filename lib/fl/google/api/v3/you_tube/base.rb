module Fl::Google::API::V3::YouTube
  # Base class for YouTube API (v3) objects using the Floopstreet YouTube developer key.

  class Base < Fl::Google::API::V3::Base
    ROOT_URL = 'https://www.googleapis.com/youtube/v3'

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
  end
end
