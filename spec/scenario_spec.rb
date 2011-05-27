require 'rubygems'
require 'ruby_gntp'
require 'ruby_gntp_spec_helper'
require File.dirname(__FILE__)+'/../lib/mingle_growl'

# use Double Ruby for mock/stub framework.
Spec::Runner.configure do |conf|
  conf.mock_with :rr
end

describe "scenarios" do
  include GNTPExampleHelperMethods
  require 'fakeweb'
  require 'fakefs/spec_helpers'
  include FakeFS::SpecHelpers

  before do
    @received_messages = []
    @ok_response = StringIO.new(["GNTP/1.0 -OK NONE\r\n", "\r\n"].join)
    @opened_socket = create_stub_socket(@ok_response, @received_messages)

    FakeWeb.register_uri(:get, "https://user:password@mingle.events.com/api/v2/projects/project1/feeds/events.xml", :body => events)
  end

  it "growls the event from mingle" do
    text = 'Something changed'

    mingle_growl.growl

    @received_messages.last.should have_application_name 'Mingle Growl'
    @received_messages.last.should have_title 'Story #26 As a user I want this to work'

    [
     "Notification-Text: #{text}\r\n"
    ].each {|expected_text|
      @received_messages.last.should include(expected_text)
    }
  end

  def mingle_growl
    mingle_access = MingleEvents::MingleBasicAuthAccess.new(
                                                            'https://mingle.events.com',
                                                            'user',
                                                            'password'
                                                            )

    MingleGrowl.new(mingle_access, File.dirname('bookmark'), 'project1')
  end
end

Spec::Matchers.define :have_application_name do |expected_value|
  MESSAGE_HEADER = 'Application-Name'

  match do |message|
    actual_value = message.select {|l| l.include? MESSAGE_HEADER }.first || ''
    actual_value = actual_value.strip
    actual_value == "#{MESSAGE_HEADER}: #{expected_value}"
  end

  failure_message_for_should do |message|
    "expected GNTP message to have '{#MESSAGE_HEADER}: #{expected_value}' but was '#{actual_value}'"
  end
end

Spec::Matchers.define :have_title do |expected_value|
  MESSAGE_HEADER = 'Notification-Title'

  match do |message|
    @actual_value = message.select {|l| l.include? MESSAGE_HEADER }.first || ''
    @actual_value = @actual_value.strip
    @actual_value == "#{MESSAGE_HEADER}: #{expected_value}"
  end

  failure_message_for_should do |message|
    "expected GNTP message to have '#{MESSAGE_HEADER}: #{expected_value}' but was '#{@actual_value}'"
  end
end

def events
  <<EVENTS
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:mingle="http://www.thoughtworks-studios.com/ns/mingle">
  <entry>
    <id>http://mingle.events.com/projects/project1/events/index/413027</id>
    <title>Story #26 As a user I want this to work</title>
    <category term="card" scheme="http://www.thoughtworks-studios.com/ns/mingle#categories"/>
  </entry>
</feed>
EVENTS
end
