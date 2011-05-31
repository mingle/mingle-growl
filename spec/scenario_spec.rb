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

    notifications.should have(4).items

    notifications.each { |message| message.should have_application_name 'Mingle Growl' }

    notifications[0].should have_title 'Story #27 As a user I want to create new things created'
    notifications[0].should_not have_header 'Notification-Text'

    notifications[1].should have_title 'Story #26 As a user I want this to work changed'
    notifications[1].should have_text 'Story Status changed from In QA to Done'

    notifications[2].should have_title 'Story #32 As a user I want to change things changed'
    notifications[2].should have_text 'Name changed from As a user I want things to change'

    notifications[3].should have_title "Bug #2 I didn't want this deleted"
    notifications[3].should_not have_header 'Notification-Text'
  end

  def mingle_growl
    mingle_access = MingleEvents::MingleBasicAuthAccess.new(
                                                            'https://mingle.events.com',
                                                            'user',
                                                            'password'
                                                            )

    MingleGrowl.new(mingle_access, File.dirname('bookmark'), 'project1')
  end

  def notifications
    @received_messages.select {|m| m.find {|l| l.include? 'GNTP/1.0 NOTIFY' } }
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

Spec::Matchers.define :have_header do |header|
  match do |message|
    message.find { |l| l.include? header }
  end
end

def events
  <<EVENTS
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:mingle="http://www.thoughtworks-studios.com/ns/mingle">
  <entry>
    <id>https://mingle.events.com/projects/project1/events/index/45000</id>
    <title>Bug #2 I didn't want this deleted</title>
    <updated>2011-05-31T10:55:38Z</updated>
    <category term="card" scheme="http://www.thoughtworks-studios.com/ns/mingle#categories"/>
    <category term="card-deletion" scheme="http://www.thoughtworks-studios.com/ns/mingle#categories"/>
    <content type="application/vnd.mingle+xml">
      <changes xmlns="http://www.thoughtworks-studios.com/ns/mingle">
        <change type="card-deletion">
        </change>
      </changes>
    </content>
  </entry>
  <entry>
    <id>https://mingle.events.com/projects/project1/events/index/41888</id>
    <title>Story #32 As a user I want to change things changed</title>
    <category term="card" scheme="http://www.thoughtworks-studios.com/ns/mingle#categories"/>
    <category term="name-change" scheme="http://www.thoughtworks-studios.com/ns/mingle#categories"/>
    <content type="application/vnd.mingle+xml">
      <changes xmlns="http://www.thoughtworks-studios.com/ns/mingle">
        <change type="name-change">
          <old_value>As a user I want things to change</old_value>
          <new_value>As a user I want to change things</new_value>
        </change>
      </changes>
    </content>
  </entry>
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
  <entry>
    <id>https://mingle.events.com/projects/project1/events/index/41900</id>
    <title>Story #27 As a user I want to create new things created</title>
    <category term="card" scheme="http://www.thoughtworks-studios.com/ns/mingle#categories"/>
    <category term="card-creation" scheme="http://www.thoughtworks-studios.com/ns/mingle#categories"/>
    <category term="card-type-change" scheme="http://www.thoughtworks-studios.com/ns/mingle#categories"/>
    <category term="name-change" scheme="http://www.thoughtworks-studios.com/ns/mingle#categories"/>
    <content type="application/vnd.mingle+xml">
      <changes xmlns="http://www.thoughtworks-studios.com/ns/mingle">
        <change type="card-creation"/>
        <change type="card-type-change">
          <old_value nil="true"></old_value>
          <new_value>
            <card_type url="https://mingle05.thoughtworks.com/api/v2/projects/studios_technical_solutions/card_types/184.xml">
              <name>Story</name>
            </card_type>
          </new_value>
        </change>
        <change type="name-change">
          <old_value nil="true"></old_value>
          <new_value>Story #27 As a user I want to create new things created</new_value>
        </change>
      </changes>
    </content>
  </entry>
</feed>
EVENTS
end
