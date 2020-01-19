require 'net/http'
require 'uri'

module Fl::Google::API::V3
  # Base class for Google API V3 objects.
  #
  # Note that we don't verify the SSL certificate, which is a security vulnerability.
  # At some point we will have to tighten this, but since all we are doing is get the
  # access and refresh tokens, we are probably OK for the time being.
  # See http://www.rubyinside.com/nethttp-cheat-sheet-2940.html and
  # http://stackoverflow.com/questions/6646550/nethttp-post-form-throws-eoferror

  class Base
    # The default value for the URL to refresh tokens.

    DEFAULT_TOKEN_REFRESH_URL = 'https://accounts.google.com/o/oauth2/token'

    # @!visibility private

    MANDATORY_CONFIG_OPTIONS = [ :root_url ]

    # The default value for the user agent string.

    DEFAULT_USER_AGENT = 'FloopStreet Google API/v3 Ruby'

    # Initializer.
    #
    # @param config A hash containing configuration options.
    #  The base class supports the following keys; subclasses may add their own.
    #  - :root_url The URL to the server that provides the API.
    #  - :access_token The Google access token.
    #  - :token_type The access token type.
    #  - :refresh_token The Google refresh token.
    #  - :token_refresh_url The URL to use for refreshing tokens. A default value is used if one is
    #    not given explicitly.
    #  - :access_key Instead of :access_token and :token_type, API objects should use the
    #    :access_key option. The reason is that, if the access token expires, the API will
    #    attempt to refresh it, and update the access key in the database with the new token.
    #  - :user_agent The value for the User-Agent request header. A default value is used if one
    #    is not given explicitly.
    #
    # @note The following configuration options are mandatory: :root_url.
    #
    # @raise [RuntimeError] Raised if a mandatory configuration option is not present.

    def initialize(config = {})
      @config = {
      }

      config.each { |k, v| @config[k] = v }

      @config[:token_refresh_url] = DEFAULT_TOKEN_REFRESH_URL unless @config.has_key?(:token_refresh_url)
      @config[:user_agent] = DEFAULT_USER_AGENT unless @config.has_key?(:user_agent)

      MANDATORY_CONFIG_OPTIONS.each do |k|
        raise "Missing :#{k} in Google API V3 configuration" unless @config.has_key?(k)
      end
    end

    # The access key for this request, if any.
    #
    # @return return the value of the :access_key configuration option.

    def access_key()
      @config[:access_key]
    end

    # Refresh the access token for an access key.
    # If the refresh is succesful, also saves the new token in the key's access data.
    #
    # @param akey The access key to use; if @c nil, use the one in the configuration.
    #
    # @return Returns @c true on success, @c fals on failure.

    def refresh_access_token(akey = nil)
      akey = @config[:access_key] unless akey
      if akey
        adata = akey.access_data

        if adata.has_key?(:refresh_token)
          provider = akey.provider

          parsed_url = URI.parse(@config[:token_refresh_url])
          http = Net::HTTP.new(parsed_url.host, parsed_url.port)
          if parsed_url.scheme.to_sym == :https
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end
          
          request = Net::HTTP::Post.new(parsed_url.request_uri)
          request.set_form_data({
                                  'grant_type' => 'refresh_token',
                                  'client_id' => provider.oauth_consumer_key,
                                  'client_secret' => provider.oauth_consumer_secret,
                                  'refresh_token' => adata[:refresh_token]
                                })
          response = http.request(request)

          if response.is_a?(Net::HTTPOK)
            jdata = ActiveSupport::JSON.decode(response.body)
            jdata.each { |jk, jv| adata[jk.to_sym] = jv }
            akey.access_data = adata
            akey.save

            true
          else
            false
          end
        else
          false
        end
      else
        false
      end
    end

    # Send a request with token refresh if needed.
    # This method calls @a req and checks its return value; if a Net::HTTPUnauthorized is returned,
    # it calls refresh_access_token() and then restarts the @a req call.
    #
    # @param req A block containing the request code; this block is expected to return a Net::HTTP response.
    #
    # @return Returns a Net::HTTP response object.

    def request_with_refresh(&req)
      response = req.call

      # if the response returned a 401, and the headers contain www-authenticate, we try
      # refreshing the token before resubmitting

      if response.is_a?(Net::HTTPUnauthorized)
        auth = response['www-authenticate']

        # for the time being we ignore the actual value of the header, and hardwire the refresh URL

        if auth && (auth.length > 0)
          if refresh_access_token()
            response = req.call
          end
        end
      end

      response
    end

    # Send a GET request.
    #
    # @param path The path to place in the GET request.
    # @param query A hash containing parameters to place in the query string.
    # @param headers a hash containing additional headers to place in the request.
    #  The following headers are automatically added:
    #  - Authorization (if an access token is available) is the authorization header.
    #
    # @return Returns a Net::HTTP response object.

    def get(path, query = {}, headers = {})
      request_with_refresh { get_internal(path, query, headers) }
    end

    # Send a POST request.
    #
    # @param path The path to place in the GET request.
    # @param params A hash containing parameters to place in the submission body.
    # @param query A hash containing parameters to place in the query string.
    # @param headers a hash containing additional headers to place in the request.
    #  The following headers are automatically added:
    #  - Authorization (if an access token is available) is the authorization header.
    #
    # @return Returns a Net::HTTP response object.

    def post(path, params = {}, query = {}, headers = {})
      request_with_refresh { post_internal(path, params, query, headers) }
    end

    # Send a PUT request.
    #
    # @param path The path to place in the GET request.
    # @param params A hash containing parameters to place in the submission body.
    # @param query A hash containing parameters to place in the query string.
    # @param headers a hash containing additional headers to place in the request.
    #  The following headers are automatically added:
    #  - Authorization (if an access token is available) is the authorization header.
    #
    # @return Returns a Net::HTTP response object.

    def put(path, params = {}, query = {}, headers = {})
      request_with_refresh { put_internal(path, params, query, headers) }
    end

    # Send a PATCH request.
    #
    # @param path The path to place in the PATCH request.
    # @param params A hash containing parameters to place in the submission body.
    # @param query A hash containing parameters to place in the query string.
    # @param headers a hash containing additional headers to place in the request.
    #  The following headers are automatically added:
    #  - Authorization (if an access token is available) is the authorization header.
    #
    # @return Returns a Net::HTTP response object.

    def patch(path, params = {}, query = {}, headers = {})
      request_with_refresh { patch_internal(path, params, query, headers) }
    end

    # Send a DELETE request.
    #
    # @param path The path to place in the DELETE request.
    # @param query A hash containing parameters to place in the query string.
    # @param headers a hash containing additional headers to place in the request.
    #  The following headers are automatically added:
    #  - Authorization (if an access token is available) is the authorization header.
    #
    # @return Returns a Net::HTTP response object.

    def delete(path, query = {}, headers = {})
      request_with_refresh { delete_internal(path, query, headers) }
    end

    protected

    # Filter and otherwise process a query string.
    # This method takes a Hash argument containing query string parameters, and converts their values to
    # a simple format that can be strung together to form a query string (essentially it is expected to
    # convert values to appropriately formatted strings).
    # It may also elect to drop query keys that are inconsistent with others.
    #
    # For example, the YouTube API converts @c :fields and @c :part, which are passed as an array of
    # strings, into comma-separated strings (except that it is lazy and it lets #expand_query do that instead).
    # And the Calendar API filters out keys like @c :orderBy if the @c :syncToken key is present.
    #
    # This method is called by the method that generates the query string.
    # The default implementation simply returns @a query: no processing is done.
    #
    # @param query A hash containing the query parameters.
    #
    # @return Returns a hash containing the processed values.

    def filter_query(query = {})
      query
    end

    # Expand a query string.
    # This method strings together query string parameters, with special processing for array values.
    # Array values are converted to a string containing the comma-separated list of elements, as string values.
    #
    # @param query A hash containing the query parameters.
    #
    # @return Returns the query string.

    def expand_query(query = {})
      qs = ''
      filter_query(query).each do |k, v|
        if v.is_a?(Array)
          qs += "&#{k}=#{v.join(',')}"
        else
          qs += "&#{k}=#{v}"
        end
      end

      (qs.length > 0) ? qs[1, qs.length] : ''
    end

    private

    def get_internal(path, query = {}, headers = {})
      url = append_query(@config[:root_url] + path, query)
      parsed_url = URI.parse(url)
      make_http(parsed_url).start do |http|
        request = Net::HTTP::Get.new(parsed_url.request_uri)
        set_headers_for_request(request, headers)

        http.request(request)
      end
    end

    def post_internal(path, params = {}, query = {}, headers = {})
      url = append_query(@config[:root_url] + path, query)
      parsed_url = URI.parse(url)

      make_http(parsed_url).start do |http|
        request = Net::HTTP::Post.new(parsed_url.request_uri)
        set_headers_for_request(request, headers)
        request['Content-Type'] = 'application/json'

        request.body = ActiveSupport::JSON.encode(params)

        http.request(request)
      end
    end

    def put_internal(path, params = {}, query = {}, headers = {})
      url = append_query(@config[:root_url] + path, query)
      parsed_url = URI.parse(url)

      make_http(parsed_url).start do |http|
        request = Net::HTTP::Put.new(parsed_url.request_uri)
        set_headers_for_request(request, headers)
        request['Content-Type'] = 'application/json'

        request.body = ActiveSupport::JSON.encode(params)

        http.request(request)
      end
    end

    def patch_internal(path, params = {}, query = {}, headers = {})
      url = append_query(@config[:root_url] + path, query)
      parsed_url = URI.parse(url)

      make_http(parsed_url).start do |http|
        request = Net::HTTP::Patch.new(parsed_url.request_uri)
        set_headers_for_request(request, headers)
        request['Content-Type'] = 'application/json'

        request.body = ActiveSupport::JSON.encode(params)

        http.request(request)
      end
    end

    def delete_internal(path, query = {}, headers = {})
      url = append_query(@config[:root_url] + path, query)
      parsed_url = URI.parse(url)

      make_http(parsed_url).start do |http|
        request = Net::HTTP::Delete.new(parsed_url.request_uri)
        set_headers_for_request(request, headers)

        http.request(request)
      end
    end
      
    def set_headers_for_request(request, headers = {})
      if @config.has_key?(:access_key) && @config[:access_key].is_a?(Fl::Db::Core::AccessKey)
        adata = @config[:access_key].access_data
        request['Authorization'] = "#{adata[:token_type]} #{adata[:access_token]}"
      elsif @config.has_key?(:access_token) && @config.has_key?(:token_type)
        request['Authorization'] = "#{@config[:token_type]} #{@config[:access_token]}"
      end

      request['User-Agent'] = if @config.has_key?(:user_agent)
                                @config[:user_agent]
                              else
                                DEFAULT_USER_AGENT
                              end

      headers.each do |k, v|
        sk = k.to_s
        request[sk] = v
      end
    end

    def make_http(parsed_url)
      http = Net::HTTP.new(parsed_url.host, parsed_url.port)
      if parsed_url.scheme.to_sym == :https
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      http
    end

    def append_query(url, query = {})
      qs = expand_query(query)
      if qs.length > 0
        url += '?'
        url += qs
      end
      
      url
    end
  end
end
