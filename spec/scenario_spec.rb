require 'rubygems'
require 'ruby_gntp'
require 'ruby_gntp_spec_helper'

# use Double Ruby for mock/stub framework.
Spec::Runner.configure do |conf|
  conf.mock_with :rr
end

# describe GNTP behavior
describe GNTP do
  include GNTPExampleHelperMethods

  before do
    @sended_messages = []
    @ok_response = StringIO.new(["GNTP/1.0 -OK NONE\r\n", "\r\n"].join)
    @opened_socket = create_stub_socket(@ok_response, @sended_messages)
  end

  it "can register notification with minimum params" do
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
