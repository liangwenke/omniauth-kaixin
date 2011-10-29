require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies

    # Authenticate to Kaixin001 utilizing OAuth 2.0 and retrieve 
    # basic user information.
    #
    # OAuth 2.0 - Kaixin001 Documentation	
    # http://wiki.open.kaixin001.com/
    # 
    # Apply kaixin001 key here:
    # http://www.kaixin001.com/platform/rapp/rapp.php
    # adapted from https://github.com/yzhang/omniauth/commit/eafc5ff8115bcc7d62c461d4774658979dd0a48e    

    class Kaixin < OmniAuth::Strategies::OAuth2
      def initialize(client_id, client_secrent)
        super
        
        puts options.inspect 
        options.client_options = {
          :site          => 'https://api.kaixin001.com/',
          :authorize_url => '/oauth2/authorize',
          :token_url     => '/oauth2/access_token',
          :token_method  => :get
        }
      end

      info do
        {
          :uid => raw_info['uid'],
          :user_info => raw_info['data']['name'],
          :location => raw_info['data']['location'],
          :image => raw_info['data']['head'],
          :description => raw_info['description'],
          :extra => {
            'user_hash' => user_data,
          }
        }
      end

      extra do
        { :raw_info => raw_info }
      end
      
      def callback_phase
        
        if request.params['error'] || request.params['error_reason']
          raise CallbackError.new(request.params['error'], request.params['error_description'] || request.params['error_reason'], request.params['error_uri'])
        end

        self.access_token = build_access_token
        self.access_token = client.auth_code.refresh_token(access_token.refresh_token) if access_token.expired?

        super
      rescue ::OAuth2::Error, CallbackError => e
        fail!(:invalid_credentials, e)
      rescue ::MultiJson::DecodeError => e
        fail!(:invalid_response, e)
      rescue ::Timeout::Error, ::Errno::ETIMEDOUT => e
        fail!(:timeout, e)
      end
      
      credentials do
        prune!({
          'expires' => access_token.expires?,
          'expires_at' => access_token.expires_at
        })
      end
      
      def user_info
        {
          'uid'    => raw_info['uid'],
          'name'   => raw_info['name'],
          'gender' => raw_info['gender'],
        }
      end

      def raw_info
        @raw_info ||= MultiJson.decode(access_token.get("/users/me.json?access_token=#{@access_token.token}").body)
      rescue ::Errno::ETIMEDOUT
        raise ::Timeout::Error
      end
    end
  end
end
