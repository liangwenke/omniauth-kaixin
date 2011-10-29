require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Kaixin < OmniAuth::Strategies::OAuth2
      option :client_options, {
        :site          => 'https://api.kaixin001.com/',
        :authorize_url => '/oauth2/authorize',
        :token_url     => '/oauth2/access_token',
        :token_method  => :get
      }
      def request_phase
        super
      end

      uid { raw_info['id'] }

      info do
        {
          'nickname' => raw_info['login'],
          'email' => raw_info['email'],
          'name' => raw_info['name'],
          'urls' => {
            'GitHub' => "https://github.com/#{raw_info['login']}",
            'Blog' => raw_info['blog'],
          },
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

