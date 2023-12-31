# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Database::LoadBalancing::Resolver do
  describe '#resolve' do
    let(:ip_addr) { IPAddr.new('127.0.0.2') }

    context 'when nameserver is an IP' do
      it 'returns an IPAddr object' do
        service = described_class.new('127.0.0.2')

        expect(service.resolve).to eq(ip_addr)
      end
    end

    context 'when nameserver is not an IP' do
      subject { described_class.new('localhost').resolve }

      it 'looks the nameserver up in the hosts file' do
        allow_any_instance_of(Resolv::Hosts).to receive(:getaddress)
          .with('localhost')
          .and_return('127.0.0.2')

        expect(subject).to eq(ip_addr)
      end

      context 'when nameserver is not in the hosts file' do
        it 'looks the nameserver up in DNS' do
          resource = double(:resource, address: ip_addr)
          packet = double(:packet, answer: [resource])

          allow_any_instance_of(Resolv::Hosts).to receive(:getaddress)
            .with('localhost')
            .and_raise(Resolv::ResolvError)

          allow(Net::DNS::Resolver).to receive(:start)
            .with('localhost', Net::DNS::A)
            .and_return(packet)

          expect(subject).to eq(ip_addr)
        end

        context 'when nameserver is not in DNS' do
          it 'raises an exception' do
            allow_any_instance_of(Resolv::Hosts).to receive(:getaddress)
              .with('localhost')
              .and_raise(Resolv::ResolvError)

            allow(Net::DNS::Resolver).to receive(:start)
              .with('localhost', Net::DNS::A)
              .and_return(double(:packet, answer: []))

            expect { subject }.to raise_exception(
              described_class::UnresolvableNameserverError,
              'could not resolve localhost'
            )
          end
        end
      end
    end
  end
end
