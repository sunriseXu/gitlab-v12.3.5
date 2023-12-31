# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Auth::Smartcard::SANExtension do
  let(:fqdn) { 'gitlab.example.com' }
  let(:extension_factory) { OpenSSL::X509::ExtensionFactory.new(nil, cert) }
  let(:san_extension) { described_class.new(cert, fqdn)}

  let(:cert) do
    key = OpenSSL::PKey::RSA.new 2048
    name = OpenSSL::X509::Name.parse 'CN=nobody/DC=example'

    cert = OpenSSL::X509::Certificate.new
    cert.version = 3
    cert.serial = 0
    cert.not_before = Time.now
    cert.not_after = Time.now + 3600
    cert.public_key = key.public_key
    cert.subject = name
    cert
  end

  def add_san_entry(value)
    cert.add_extension extension_factory.create_extension('subjectAltName', value)
  end

  describe '#alternate_emails' do
    subject { san_extension.alternate_emails }

    context 'without SAN extensions' do
      it { is_expected.to be_empty }
    end

    context 'with SAN extensions' do
      describe 'single extension' do
        let(:uri) { 'https://gitlab.example.com' }

        before do
          add_san_entry "URI:#{uri}"
        end

        it { is_expected.to match([{ described_class::URI_TAG => uri }]) }
      end

      describe 'multiple entries using ASN1' do
        let(:email) { 'my@other.address' }
        let(:uri) { '1.2.3.4' }

        before do
          add_san_entry "email:#{email},URI:#{uri}"
        end

        it {
          is_expected.to match([{
                                      described_class::EMAIL_TAG => email,
                                      described_class::URI_TAG => uri
                                    }])
        }
      end

      describe 'custom General Name' do
        it 'can\'t use custom alt names that are not part of general names' do
          expect { add_san_entry 'customName:some@gitlab.com' }
            .to raise_error OpenSSL::X509::ExtensionError
        end
      end
    end
  end

  describe '#email_identity' do
    let(:san_email) { 'newemail@some.domain' }
    let(:san_uri) { "https://#{fqdn}" }

    before do
      allow(Gitlab.config.gitlab).to receive(:host).and_return(fqdn)
    end

    subject { san_extension.email_identity }

    describe 'alternate name email for GitLab defined in the certificate' do
      before do
        add_san_entry "email:#{san_email},URI:#{san_uri}"
      end

      it { is_expected.to eq san_email }

      describe 'inappropriate URI format' do
        let(:san_uri) { 'an invalid uri' }

        it { is_expected.to be_nil }
      end
    end

    describe 'no alternate name defined to use with GitLab' do
      it { is_expected.to be_nil }
    end

    context 'when the host is partially matched to the URI' do
      let(:forged_uri) { "https://#{fqdn}.anotherdomain.com" }
      let(:forged_identity) { 'hacker@email.com' }

      before do
        add_san_entry "email:#{forged_identity},URI:#{forged_uri}"
      end

      it { is_expected.to be_nil }
    end
  end
end
