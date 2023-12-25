# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Email::Receiver do
  include_context :email_shared_context

  context "when the email contains a valid email address in a Delivered-To header" do
    let(:email_raw) { fixture_file('emails/forwarded_new_issue.eml') }
    let(:handler) { double(:handler) }

    before do
      stub_incoming_email_setting(enabled: true, address: "incoming+%{key}@appmail.adventuretime.ooo")

      allow(handler).to receive(:execute)
      allow(handler).to receive(:metrics_params)
      allow(handler).to receive(:metrics_event)
    end

    it "finds the mail key" do
      expect(Gitlab::Email::Handler).to receive(:for).with(an_instance_of(Mail::Message), 'gitlabhq/gitlabhq+auth_token').and_return(handler)

      receiver.execute
    end
  end

  context "when we cannot find a capable handler" do
    let(:email_raw) { fixture_file('emails/valid_reply.eml').gsub(mail_key, "!!!") }

    it "raises an UnknownIncomingEmail error" do
      expect { receiver.execute }.to raise_error(Gitlab::Email::UnknownIncomingEmail)
    end
  end

  context "when the email is blank" do
    let(:email_raw) { "" }

    it "raises an EmptyEmailError" do
      expect { receiver.execute }.to raise_error(Gitlab::Email::EmptyEmailError)
    end
  end

  context "when the email was auto generated" do
    let(:email_raw) { fixture_file("emails/auto_reply.eml") }

    it "raises an AutoGeneratedEmailError" do
      expect { receiver.execute }.to raise_error(Gitlab::Email::AutoGeneratedEmailError)
    end
  end

  it "requires all handlers to have a unique metric_event" do
    events = Gitlab::Email::Handler.handlers.map do |handler|
      handler.new(Mail::Message.new, 'gitlabhq/gitlabhq+auth_token').metrics_event
    end

    expect(events.uniq.count).to eq events.count
  end
end