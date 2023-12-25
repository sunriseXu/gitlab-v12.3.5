# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Auth::Smartcard::LDAPCertificate do
  let(:certificate_header) { 'certificate' }
  let(:openssl_certificate_store) { instance_double(OpenSSL::X509::Store) }
  let(:user_build_service) { instance_double(Users::BuildService) }
  let(:subject_ldap_dn) { 'subject_ldap_dn' }
  let(:issuer) { instance_double(OpenSSL::X509::Name, to_s: 'issuer_dn') }
  let(:openssl_certificate) do
    instance_double(OpenSSL::X509::Certificate,
                    { issuer: issuer,
                      serial: '42' } )
  end
  let(:ldap_provider) { 'ldapmain' }
  let(:ldap_connection) { instance_double(::Net::LDAP) }
  let(:ldap_person_name) { 'John Doe' }
  let(:ldap_person_email) { 'john.doe@example.com' }
  let(:ldap_entry) do
    Net::LDAP::Entry.new.tap do |entry|
      entry['dn'] = subject_ldap_dn
      entry['uid'] = 'john doe'
      entry['cn'] = ldap_person_name
      entry['mail'] = ldap_person_email
    end
  end
  let(:ldap_person) { ::Gitlab::Auth::LDAP::Person.new(ldap_entry, ldap_provider) }

  before do
    allow(described_class).to(
      receive(:store).and_return(openssl_certificate_store))
    allow(OpenSSL::X509::Certificate).to(
      receive(:new).and_return(openssl_certificate))
    allow(openssl_certificate_store).to(
      receive(:verify).and_return(true))
    allow(Net::LDAP).to receive(:new).and_return(ldap_connection)
    allow(ldap_connection).to receive(:search).and_return([ldap_entry])
  end

  describe '#find_or_create_user' do
    subject { described_class.new(ldap_provider, certificate_header).find_or_create_user }

    context 'user already exists' do
      let(:user) { create(:user) }

      before do
        create(:identity, { provider: ldap_provider,
                            extern_uid: subject_ldap_dn,
                            user: user })
      end

      it 'finds existing user' do
        expect(subject).to eql(user)
      end

      it 'does not create new user' do
        expect { subject }.not_to change { User.count }
      end
    end

    context 'user does not exist' do
      let(:user) { create(:user) }

      it 'creates user' do
        expect { subject }.to change { User.count }.from(0).to(1)
      end

      it 'creates user with correct attributes' do
        subject

        user = User.find_by(username: 'johndoe')

        expect(user).not_to be_nil
        expect(user.email).to eql(ldap_person_email)
      end

      it 'creates identity' do
        expect { subject }.to change { Identity.count }.from(0).to(1)
      end

      it 'creates identity with correct attributes' do
        subject

        identity = Identity.find_by(provider: ldap_provider, extern_uid: subject_ldap_dn)

        expect(identity).not_to be_nil
      end

      it 'calls Users::BuildService with correct params' do
        user_params = { name: ldap_person_name,
                        username: 'johndoe',
                        email: ldap_person_email,
                        extern_uid: 'subject_ldap_dn',
                        provider: ldap_provider,
                        password_automatically_set: true,
                        skip_confirmation: true }

        expect(Users::BuildService).to(
          receive(:new)
            .with(nil, hash_including(user_params))
            .and_return(user_build_service))
        expect(user_build_service).to(
          receive(:execute).with(skip_authorization: true).and_return(user))

        subject
      end

      context 'username generation' do
        context 'uses LDAP uid' do
          it 'creates user with correct username' do
            subject

            user = User.find_by(username: 'johndoe')
            expect(user).not_to be_nil
          end
        end

        context 'avoids conflicting namespaces' do
          let!(:existing_user) { create(:user, username: 'johndoe') }

          it 'creates user with correct username' do
            expect { subject }.to change { User.count }.from(1).to(2)
            expect(User.last.username).to eql('johndoe1')
          end
        end
      end
    end

    it_behaves_like 'a valid certificate is required'
  end

  it_behaves_like 'a certificate store'
end
