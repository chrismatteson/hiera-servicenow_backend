# The `servicenow_data` is a hiera 5 `data_hash` data provider function.
#
require 'lookup_http'
require 'json'
require 'yaml'

Puppet::Functions.create_function(:servicenow_data) do

  dispatch :servicenow_data do
    param 'Hash', :options
    param 'Puppet::LookupContext', :context
  end

#  argument_mismatch :missing_params do
#    param 'Hash', :options
#    param 'Puppet::LookupContext', :context
#  end

  def servicenow_data(options, context)

    result = http_get(context, options)

    answer = result.is_a?(Hash) ? result[key] : result
    context.not_found if answer.nil?
    return answer
  end

  def http_get(options, context)
    instance = options['instance']
    username = options['username']
    password = options['password']
    webservice = options['webservice']
    uri = URI.parse(options['uri'])

    host, port, path = uri.host, uri.port, URI.escape(context.interpolate(uri.request_uri))

    if context.cache_has_key(path)
      context.explain { "Returning cached value for #{path}" }
      return context.cached_value(path)
    else
      context.explain { "Querying #{uri}" }
      lookup_params = {}
      options.each do |k,v|
        lookup_params[k.to_sym] = v if lookup_supported_params.include?(k.to_sym)
      end
      http_handler = LookupHttp.new(lookup_params.merge({:host => host, :port => port}))

      begin
        response = http_handler.get_parsed(path)
        context.cache(path, response)
        return response
      rescue LookupHttp::LookupError => e
        raise Puppet::DataBinding::LookupError, "lookup_http failed #{e.message}"
      end
    end
  end

  def lookup_supported_params
    [
      :output,
      :failure,
      :ignore_404,
      :headers,
      :http_connect_timeout,
      :http_read_timeout,
      :use_ssl,
      :ssl_ca_cert,
      :ssl_cert,
      :ssl_key,
      :ssl_verify,
      :use_auth,
      :auth_user,
      :auth_pass,
    ]
  end
end
