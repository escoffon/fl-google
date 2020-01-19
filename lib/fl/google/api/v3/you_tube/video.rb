module Fl::Google::API::V3::YouTube
  # Class to manage videos.

  class Video < Fl::Google::API::V3::YouTube::Base
    PATH_ROOT = '/videos'

    # Initializer.
    #
    # @param config A hash containing configuration options.

    def initialize(config = {})
      super(config)
    end

    # Get video metadata for a video.
    #
    # @param video_id The video identifier, or an array of video identifiers; this will be placed in the
    #  query string as the :id parameter.
    # @param query Query string parameters. The :part parameter can be an array of symbols specifying the
    #  :part values; these will be converted into a comma-separated string. Default value for :part
    #  is :contentDetails. Similarly for the :fields parameter.
    #
    # @return Returns a Net::HTTP response object, so that the caller can check for errors and
    #  response status. The channel data are available in the response body.

    def get_video_data(video_id, query = {})
      nq = query.dup

      nq[:id] = if video_id.is_a?(Array)
                  video_id.join(',')
                else
                  video_id
                end

      nq[:part] = [] unless query.has_key?(:part)
      part = nq[:part].is_a?(Array) ? nq[:part] : [ nq[:part] ]
      part << :snippet unless part.include?(:snippet)
      part << :contentDetails unless part.include?(:contentDetails)
      nq[:part] = part

      self.get(PATH_ROOT, nq)
    end

    # Get video metadata.
    # This method returns the video resource data from the API call, and it contains the following
    # parts: :snippet and :contentDetails.
    #
    # @param video_id The video identifier; this will be placed in the query string as the :id parameter.
    # @param query A hash containing query parameters to override the defaults.
    #  - :part The list of parts to return; the default is [ :contentDetails, :snippet ].
    #
    # @return Returns a hash containing the metadata for the video, @c nil in case of errors.

    def get_video_metadata(video_id, query = {})
      q = {
        :part => [ :contentDetails, :snippet ]
      }
      query.each { |qk, qv| q[qk] = qv }

      response = self.get_video_data(video_id, q)
      if response.is_a?(Net::HTTPOK)
        json = ActiveSupport::JSON.decode(response.body)
        items = json['items']
        if items.is_a?(Array)
          info = items[0]
        end
      else
        info = nil
      end

      info
    end
  end
end
