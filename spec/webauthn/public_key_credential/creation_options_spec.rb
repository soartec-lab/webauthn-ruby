# frozen_string_literal: true

require "spec_helper"
require "webauthn/public_key_credential/creation_options"

RSpec.describe WebAuthn::PublicKeyCredential::CreationOptions do
  let(:creation_options) do
    WebAuthn::PublicKeyCredential::CreationOptions.new(
      user: { id: "1", name: "User", display_name: "User Display" }
    )
  end

  it "has a challenge" do
    expect(creation_options.challenge.class).to eq(String)
    expect(creation_options.challenge.encoding).to eq(Encoding::ASCII_8BIT)
    expect(creation_options.challenge.length).to eq(32)
  end

  context "public key params" do
    it "has default public key params" do
      params = creation_options.pub_key_cred_params

      array = if OpenSSL::PKey::RSA.instance_methods.include?(:verify_pss)
                [
                  { type: "public-key", alg: -7 },
                  { type: "public-key", alg: -37 },
                  { type: "public-key", alg: -257 },
                ]
              else
                [
                  { type: "public-key", alg: -7 },
                  { type: "public-key", alg: -257 },
                ]
              end

      expect(params).to match_array(array)
    end

    context "when extra alg added" do
      before do
        WebAuthn.configuration.algorithms << "RS1"
      end

      it "is added to public key params" do
        params = creation_options.pub_key_cred_params

        array = if OpenSSL::PKey::RSA.instance_methods.include?(:verify_pss)
                  [
                    { type: "public-key", alg: -7 },
                    { type: "public-key", alg: -37 },
                    { type: "public-key", alg: -257 },
                    { type: "public-key", alg: -65535 },
                  ]
                else
                  [
                    { type: "public-key", alg: -7 },
                    { type: "public-key", alg: -257 },
                    { type: "public-key", alg: -65535 },
                  ]
                end

        expect(params).to match_array(array)
      end
    end
  end

  context "Relying Party info" do
    it "has relying party name default to nothing" do
      expect(creation_options.rp.name).to eq(nil)
    end

    context "when configured" do
      before do
        WebAuthn.configuration.rp_name = "Example Inc."
        WebAuthn.configuration.rp_id = "example.com"
      end

      it "has the configured values" do
        expect(creation_options.rp.name).to eq("Example Inc.")
        expect(creation_options.rp.id).to eq("example.com")
      end
    end
  end

  it "has user info" do
    expect(creation_options.user.id).to eq("1")
    expect(creation_options.user.name).to eq("User")
    expect(creation_options.user.display_name).to eq("User Display")
  end

  context "client timeout" do
    it "has a default client timeout" do
      expect(creation_options.timeout).to(eq(120000))
    end

    context "when client timeout is configured" do
      before do
        WebAuthn.configuration.credential_options_timeout = 60000
      end

      it "updates the client timeout" do
        expect(creation_options.timeout).to(eq(60000))
      end
    end
  end

  it "has everything" do
    options = WebAuthn::PublicKeyCredential::CreationOptions.new(
      rp: {
        id: "rp-id",
        name: "rp-name",
        icon: "rp-icon-url"
      },
      user: {
        id: "user-id",
        name: "user-name",
        display_name: "user-display-name",
        icon: "user-icon-url"
      },
      pub_key_cred_params: [{ type: "public-key", alg: -7 }],
      timeout: 10_000,
      exclude_credentials: [{ type: "public-key", id: "credential-id", transports: ["usb", "nfc"] }],
      authenticator_selection: {
        authenticator_attachment: "cross-platform",
        resident_key: "required",
        user_verification: "required"
      },
      attestation: "direct",
      extensions: { whatever: "whatever" },
    )

    hash = options.as_json

    expect(hash[:rp]).to eq(id: "rp-id", name: "rp-name", icon: "rp-icon-url")
    expect(hash[:user]).to eq(
      id: "user-id", name: "user-name", icon: "user-icon-url", displayName: "user-display-name"
    )
    expect(hash[:pubKeyCredParams]).to eq([{ type: "public-key", alg: -7 }])
    expect(hash[:timeout]).to eq(10_000)
    expect(hash[:excludeCredentials]).to eq([{ type: "public-key", id: "credential-id", transports: ["usb", "nfc"] }])
    expect(hash[:authenticatorSelection]).to eq(
      authenticatorAttachment: "cross-platform", residentKey: "required", userVerification: "required"
    )
    expect(hash[:attestation]).to eq("direct")
    expect(hash[:extensions]).to eq(whatever: "whatever")
    expect(hash[:challenge]).to be
  end

  it "accepts shorthand for exclude_credentials" do
    options = WebAuthn::PublicKeyCredential::CreationOptions.new(user: { id: "id", name: "name" }, exclude: "id")

    expect(options.exclude).to eq("id")
    expect(options.exclude_credentials).to eq([{ type: "public-key", id: "id" }])
    expect(options.as_json[:excludeCredentials]).to eq([{ type: "public-key", id: "id" }])
  end

  it "accepts alg name for pub_key_cred_params" do
    options = WebAuthn::PublicKeyCredential::CreationOptions.new(user: { id: "id", name: "name" }, algs: "RS256")

    expect(options.algs).to eq("RS256")
    expect(options.pub_key_cred_params).to eq([{ type: "public-key", alg: -257 }])
    expect(options.as_json[:pubKeyCredParams]).to eq([{ type: "public-key", alg: -257 }])
  end

  it "accepts alg id for pub_key_cred_params" do
    options = WebAuthn::PublicKeyCredential::CreationOptions.new(user: { id: "id", name: "name" }, algs: -257)

    expect(options.algs).to eq(-257)
    expect(options.pub_key_cred_params).to eq([{ type: "public-key", alg: -257 }])
    expect(options.as_json[:pubKeyCredParams]).to eq([{ type: "public-key", alg: -257 }])
  end
end
