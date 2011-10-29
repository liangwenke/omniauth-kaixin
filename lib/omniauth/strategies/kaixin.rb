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
      option :client_options = {
        :site          => 'https://api.kaixin001.com/',
        :authorize_url => '/oauth2/authorize',
        :token_url     => '/oauth2/access_token',
        :token_method  => :get
      }

      def consumer
        consumer = ::OAuth::Consumer.new(options.consumer_key, options.consumer_secret, options.client_options)
        consumer
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
