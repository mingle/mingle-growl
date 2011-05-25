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
    APP_NAME = 'ingle Growl'

    GNTP.notify({
                  :app_name => APP_NAME,
                  :title    => "Fake title",
                  :text     => "Fake text"
                })

    [
      "Application-Name: #{APP_NAME}\r\n",
    ].each {|expected_text|
      @sended_messages.last.should include(expected_text)
    }

  end
end
