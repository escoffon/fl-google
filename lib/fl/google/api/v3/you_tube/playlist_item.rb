module Fl::Google::API::V3::YouTube
  # Class to manage playlist items.

  class PlaylistItem < Fl::Google::API::V3::YouTube::Base
    PATH_ROOT = '/playlistItems'

    # Initializer.
    #
    # @param config A hash containing configuration options.

    def initialize(config = {})
      super(config)
    end

    # Get playlist item data for a given playlist.
    #
    # @param playlist The playlist name or identifier; this will be placed in the query string as the
    #  :playlistId parameter. The method first looks up @a playlist in the list of playlists for the
    #  associated access key; if a match is found, it gets the playlist identifier from it.
    #  Otherwise, it assumes that @a playlist is already an identifier.
    # @param query Query string parameters. The :part parameter can be an array of symbols specifying the
    #  :part values; these will be converted into a comma-separated string. Default value for :part
    #  is [ :contentDetails, :status ]. Similarly for the :fields parameter.
    #
    # @return Returns a Net::HTTP response object, so that the caller can check for errors and
    #  response status. The channel data are available in the response body.

    def get_playlist_item_data(playlist = 'uploads', query = {})
      nq = query.dup

      if self.access_key
        access_data = self.access_key.access_data
        if access_data
          plist = access_data[:playlists]
          if plist && plist.has_key?(playlist)
            nq[:playlistId] = plist[playlist]
          end
        end
      end

      nq[:playlistId] = playlist unless nq.has_key?(:playlistId)
      nq[:maxResults] = 20 unless nq.has_key?(:maxResults)

      nq[:part] = [] unless query.has_key?(:part)
      part = nq[:part].is_a?(Array) ? nq[:part] : [ nq[:part] ]
      part << :contentDetails unless part.include?(:contentDetails)
      part << :status unless part.include?(:status)
      nq[:part] = part

      self.get(PATH_ROOT, nq)
    end
  end
end
