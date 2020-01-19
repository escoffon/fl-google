module Fl::Google::API::V3::YouTube
  # Class to manage a user's channel.

  class Channel < Fl::Google::API::V3::YouTube::Base
    PATH_ROOT = '/channels'

    # Initializer.
    #
    # @param config A hash containing configuration options.

    def initialize(config = {})
      super(config)
    end

    # Get channel info for a user.
    #
    # @param user_id The user ID. If @c nil or the empty string, use the authenticated user; in this case,
    #  you must have provided an access token in @a config.
    # @param query Query string parameters. The :part parameter can be an array of symbols specifying the
    #  :part values; these will be converted into a comma-separated string. Default value for :part
    #  is :contentDetails. Similarly for the :fields parameter.
    #
    # @return Returns a Net::HTTP response object, so that the caller can check for errors and
    #  response status. The channel data are available in the response body.

    def get_channel_data(user_id = nil, query = {})
      nq = query.dup

      if user_id
        nq[:forUsername] = user_id
      else
        nq[:mine] = 'true'
      end

      nq[:part] = [] unless query.has_key?(:part)
      part = nq[:part].is_a?(Array) ? nq[:part] : [ nq[:part] ]
      part << :contentDetails  unless part.include?(:contentDetails)
      nq[:part] = part

      self.get(PATH_ROOT, nq)
    end

    # Get common channel information.
    # This method returns a common set of channel data, for use by the access keys.
    # The hash returned by this method contains the following keys:
    # - :channel_title A string containing the channel title.
    # - :channel_id A string containing the channel identifier.
    # - :channel_description A string containing the channel description.
    # - :playlists A hash containing the channe's playlists, as described in get_playlists
    #
    # @param user_id The user ID. If @c nil or the empty string, use the authenticated user; in this case,
    #  you must have provided an access token in @a config.
    #
    # @return Returns a hash containing the channel info for the user, @c nil in case of errors.

    def get_channel_info(user_id = nil)
      response = self.get_channel_data(user_id, {
                                         :part => [ :contentDetails, :snippet ],
                                         :fields => [ 'items/id',
                                                      'items/contentDetails/relatedPlaylists',
                                                      'items/snippet/title',
                                                      'items/snippet/description',
                                                      'items/snippet/publishedAt'
                                                    ]
                                  })
      if response.is_a?(Net::HTTPOK)
        info = {}
        json = ActiveSupport::JSON.decode(response.body)
        items = json['items']
        if items.is_a?(Array)
          first = items[0]
          if first.has_key?('contentDetails')
            info[:playlists] = first['contentDetails']['relatedPlaylists']
          end
          info[:channel_id] = first['id'] if first.has_key?('id')
          snippet = first['snippet']
          info[:channel_title] = snippet['title'] if snippet.has_key?('title')
          if snippet.has_key?('description') && (snippet['description'].length > 0)
            info[:channel_description] = snippet['description']
          end
          info[:channel_published_at] = snippet['publishedAt'] if snippet.has_key?('publishedAt')
        end
      else
        info = nil
      end

      info
    end

    # Get the playlists for a user.
    #
    # @param user_id The user ID. If @c nil or the empty string, use the authenticated user; in this case,
    #  you must have provided an access token in @a config.
    #
    # @return Returns a hash containing the playlists for the user, @c nil in case of errors.

    def get_playlists(user_id = nil)
      response = self.get_channel_data(user_id, { :part => [ :contentDetails ] })
      if response.is_a?(Net::HTTPOK)
        json = ActiveSupport::JSON.decode(response.body)
        items = json['items']
        if items.is_a?(Array) && items[0].has_key?('contentDetails')
          playlists = items[0]['contentDetails']['relatedPlaylists']
        end
      else
        playlists = nil
      end

      playlists
    end
  end
end
