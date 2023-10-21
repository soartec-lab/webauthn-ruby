# frozen_string_literal: true

require "spec_helper"

require "webauthn/public_key_credential"

RSpec.describe "PublicKeyCredential" do
  describe ".from_client" do
    it do
      expect do
        WebAuthn::PublicKeyCredential.from_client(nil)
      end.to raise_error(WebAuthn::PublicKeyCredential::RequiredError)
    end
  end
end
