require 'rubygems'
require 'mingle_events'
require 'fileutils'

class GrowlPublisher < MingleEvents::Processors::AbstractNoRetryProcessor
  require 'ruby_gntp'

  def process_event(event)
    growl_event = from(event)
    growl_event.notify
  end

  private
  def from(event)
    event.card? and return GrowlCardChanged.new event
    Silence.new
  end

  class GrowlCardChanged
    def initialize event
      @event = event
    end

    def notify
      GNTP.notify({
                    :app_name => "Mingle Growl",
                    :title    => title,
                    :text     => text,
                    :icon     => "http://www.hatena.ne.jp/users/sn/snaka72/profile.gif",
                  })
    end

    private
    def title
      @event.title
    end

    def text
      "Something changed"
    end
  end

  class Silence
    def notify
    end
  end
end

# specify mingle access
mingle_access = MingleEvents::MingleBasicAuthAccess.new(
  'http://localhost:8080',
  'mira',
  'mira'
)

# construct event processing pipelines
processors = MingleEvents::Processors::Pipeline.new([
  MingleEvents::Processors::PutsPublisher.new,
  GrowlPublisher.new
])

# assign processors to project
processors_by_project = {
  'xmail' => [processors]
}

# specify where to store event processing state
state_folder = File.dirname('bookmark')

# run the poller once.  you'll want to schedule this with cron or something similar
MingleEvents::Poller.new(mingle_access, processors_by_project, state_folder).run_once

