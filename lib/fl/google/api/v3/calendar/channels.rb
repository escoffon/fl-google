module Fl::Google::API::V3::Calendar
  # Class to manage calendar channels (mostly to stop notifications).

  class Channels < Fl::Google::API::V3::Calendar::Base
    STOP_PATH = '/channels/stop'

    # Initializer.
    #
    # @param config A hash containing configuration options.

    def initialize(config = {})
      super(config)
    end

    # Stop notifications for a given channel.
    # This method makes a request to stop calendar push notifications.
    #
    # @param channel_id The identifier of the channel for which to stop notifications.
    # @param resource_id The identifier of the resource for which to stop notifications.
    #
    # @return Returns a response object, or nil for failures before the stop call is made.
    #  The response object could contain a failure status.

    def stop_notifications(channel_id, resource_id)
      post(STOP_PATH, { :id => channel_id, :resourceId => resource_id })
    end
  end
end
