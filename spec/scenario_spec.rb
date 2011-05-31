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
    mingle_growl.growl

    @received_messages.last.should have_application_name 'Mingle Growl'
    @received_messages.last.should have_title 'Story #26 As a user I want this to work changed'
    @received_messages.last.should have_text 'Story Status changed from In QA to Done'
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

def have_application_name expected_value
  MessageMatcher.new('Application-Name', expected_value)
end

def have_title expected_value
  MessageMatcher.new('Notification-Title', expected_value)
end

def have_text expected_value
  MessageMatcher.new('Notification-Text', expected_value)
end

class MessageMatcher
  def initialize(message_header, expected_value)
    @message_header, @expected_value = message_header, expected_value
  end

  def matches?(message)
    @actual_value = message.select {|l| l.include? @message_header }.first || ''
    @actual_value = @actual_value.strip
    @actual_value == "#{@message_header}: #{@expected_value}"
  end

  def failure_message_for_should
    "expected GNTP message to have '{#@message_header}: #{@expected_value}' but was '#{@actual_value}'"
  end
end

def events
  <<EVENTS
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:mingle="http://www.thoughtworks-studios.com/ns/mingle">
  <entry>
    <id>http://mingle.events.com/projects/project1/events/index/413027</id>
    <title>Story #26 As a user I want this to work changed</title>
    <category term="card" scheme="http://www.thoughtworks-studios.com/ns/mingle#categories"/>
    <category term="property-change" scheme="http://www.thoughtworks-studios.com/ns/mingle#categories"/>
    <content type="application/vnd.mingle+xml">
      <changes xmlns="http://www.thoughtworks-studios.com/ns/mingle">
        <change type="property-change">
          <property_definition url="http://your.mingle.server:8080/api/v2/projects/test_project/property_definitions/114.xml">
            <name>Story Status</name>
            <position nil="true"></position>
            <data_type>string</data_type>
            <is_numeric type="boolean">false</is_numeric>
          </property_definition>
          <old_value>In QA</old_value>
          <new_value>Done</new_value>
        </change>
      </changes>
     </content>
  </entry>
</feed>
EVENTS
end
