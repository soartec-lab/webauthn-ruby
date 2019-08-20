# frozen_string_literal: true

require "webauthn/public_key_credential/options"

module WebAuthn
  def self.credential_request_options
    warn(
      "DEPRECATION WARNING: `WebAuthn.credential_request_options` is deprecated."\
      " Please use `WebAuthn::PublicKeyCredential.get_options` instead."
    )

    PublicKeyCredential::RequestOptions.new.as_json
  end

  class PublicKeyCredential
    def self.get_options(options, encoding: :base64url)
      WebAuthn::PublicKeyCredential::RequestOptions.new(options.merge(encoding: encoding))
    end

    class RequestOptions < Options
      attr_accessor :rp_id, :allow, :user_verification

      def initialize(rp_id: nil, allow_credentials: nil, allow: nil, user_verification: nil, **keyword_arguments)
        super(**keyword_arguments)

        @rp_id = rp_id || configuration.rp_id
        @allow_credentials = allow_credentials
        @allow = allow
        @user_verification = user_verification
      end

      def allow_credentials
        @allow_credentials || allow_credentials_from_allow || []
      end

      private

      def attributes
        super.concat([:allow_credentials, :rp_id, :user_verification])
      end

      def allow_credentials_from_allow
        if allow
          as_public_key_descriptors(allow)
        end
      end
    end
  end
end
