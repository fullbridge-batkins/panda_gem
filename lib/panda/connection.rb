module Panda
  
  API_PORT=443
  US_API_HOST="api.pandastream.com"
  EU_API_HOST="api-eu.pandastream.com"
  
  class Connection
    attr_accessor :api_host, :api_port, :access_key, :secret_key, :api_version, :cloud_id

    def initialize(auth_params={}) 
      params = { :api_host => US_API_HOST, :api_port => API_PORT }.merge!(auth_params)
      @api_version = 2

      @cloud_id   = params["cloud_id"]    || params[:cloud_id]
      @access_key = params["access_key"]  || params[:access_key]
      @secret_key = params["secret_key"]  || params[:secret_key]
      @api_host   = params["api_host"]    || params[:api_host]
      @api_port   = params["api_port"]    || params[:api_port]
      @prefix     = params["prefix_url"]  || "v#{api_version}"
    end

    def http_client
      Panda::HttpClient.new(api_url)
    end
    
    # Authenticated requests
    def get(request_uri, params={})
      sp = signed_params("GET", request_uri, params)
      http_client.get("/#{@prefix}#{request_uri}", sp)
    end

    def post(request_uri, params="")
      sp = signed_query("POST", request_uri, params)
      http_client.post("/#{@prefix}#{request_uri}", sp)
    end

    def put(request_uri, params="")
      sp = signed_query("PUT", request_uri, params)
      http_client.put("/#{@prefix}#{request_uri}", sp)
    end

    def delete(request_uri, params={})
      sp = signed_params("DELETE", request_uri, params)
      http_client.delete("/#{@prefix}#{request_uri}", sp)
    end

    # Signing methods
    def signed_query(*args)
      ApiAuthentication.hash_to_query(signed_params(*args))
    end

    def signed_params(verb, request_uri, params = {}, timestamp_str = nil)
      auth_params = stringify_keys(params)
      auth_params['cloud_id']   = cloud_id unless request_uri =~ /^\/clouds/
      auth_params['access_key'] = access_key
      auth_params['timestamp']  = timestamp_str || Time.now.utc.iso8601(6)

      auth_params['signature']  = ApiAuthentication.generate_signature(verb, request_uri, api_host, secret_key, auth_params)
      auth_params
    end

    def api_url
      "#{api_scheme}://#{api_host}:#{api_port}"
    end

    def api_scheme
      api_port.to_i == 443 ? 'https' : 'http'
    end
    
    # Shortcut to setup your bucket
    def setup_bucket(params={})
      granting_params = { 
        :s3_videos_bucket => params[:bucket],
        :aws_access_key => params[:access_key],
        :aws_secret_key => params[:secret_key]
      }

      put("/clouds/#{@cloud_id}.json", granting_params)
    end

    def to_hash
      hash = {}
      [:api_host, :api_port, :access_key, :secret_key, :api_version, :cloud_id].each do |a|
        hash[a] = send(a)
      end
      hash
    end

    private

    def stringify_keys(params)
      params.inject({}) do |options, (key, value)|
        options[key.to_s] = value
        options
      end
    end

  end
end

