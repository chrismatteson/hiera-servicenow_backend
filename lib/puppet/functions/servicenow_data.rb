# The `servicenow_data` is a hiera 5 `data_hash` data provider function.
#
require 'faraday'
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
    instance = options['instance']
    username = options['username']
    password = options['password']
    webservice = options['webservice']
    path = options['path']

    # Build connection using faradady
    conn = Faraday.new(url: instance.to_s, ssl: { verify: false }) do |faraday|
      faraday.request :url_encoded
      faraday.basic_auth(username.to_s, password.to_s)
      faraday.response :logger
      faraday.adapter Faraday.default_adapter
    end

    # Build Response using hostname and table name from the constants
    # def getServiceNowResponse(conn)
    begin
      response = conn.get do |req|
        req.url "#{WEBSERVICE}"
        req.params['sysparm_query'] = "${PATH}"
        req.params['sysparm_limit'] = 1
        req.headers['Content-Type'] = 'application/json'
      end
    rescue Faraday::Error => e
      raise('ERROR Could not connect to ServiceNow: ' + e)
    end

    # For each defined variable in the config file add a facter
    response.body.to_json
    #if result['result'].count == 0
    #  raise("ERROR There is no result in ServiceNow in #{TABLE} for #{OS_HOSTNAME}")
    #end
  end
end
