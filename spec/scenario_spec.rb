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
    app_name = 'Mingle Growl'
    title = 'Story #26 As a user I want this to work'
    text = 'Something changed'

    mingle_growl.growl

    [
     "Application-Name: #{app_name}\r\n",
     "Notification-Title: #{title}\r\n",
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

describe "spike growl stubbing" do
  include GNTPExampleHelperMethods

  before do
    @sended_messages = []
    @ok_response = StringIO.new(["GNTP/1.0 -OK NONE\r\n", "\r\n"].join)
    @opened_socket = create_stub_socket(@ok_response, @sended_messages)
  end

  it "can stub out GNTP socket" do
    APP_NAME = 'Mingle Growl'
    TITLE = 'Fake title'
    TEXT = 'Fake text'

    GNTP.notify({
                  :app_name => APP_NAME,
                  :title    => TITLE,
                  :text     => TEXT
                })

    [
     "Application-Name: #{APP_NAME}\r\n",
     "Notification-Title: #{TITLE}\r\n",
     "Notification-Text: #{TEXT}\r\n"
    ].each {|expected_text|
      @sended_messages.last.should include(expected_text)
    }
  end
end

describe "spike events stubbing" do
  require 'mingle_events'
  require 'fakeweb'
  require 'fakefs/spec_helpers'
  include FakeFS::SpecHelpers

  before do
    FakeWeb.register_uri(:get, "https://user:password@mingle.events.com/api/v2/projects/project1/feeds/events.xml", :body => events)
  end

  it "picks up events" do

    mingle_access = MingleEvents::MingleBasicAuthAccess.new(
                                                            'https://mingle.events.com',
                                                            'user',
                                                            'password'
                                                            )

    state_folder = File.dirname('bookmark')

    stub_publisher = StubPublisher.new
    processors = MingleEvents::Processors::Pipeline.new( [ stub_publisher ])

    processors_by_project = {
      'project1' => [processors]
    }

    MingleEvents::Poller.new(mingle_access, processors_by_project, state_folder).run_once

    stub_publisher.entries.should include 'http://mingle.events.com/projects/project1/events/index/413027'
  end
end

class StubPublisher < MingleEvents::Processors::AbstractNoRetryProcessor
  def process_event(entry)
    entries << entry.entry_id
  end

  def entries() @entries ||= [] end
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
