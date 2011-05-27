require 'rubygems'
require 'mingle_events'
require 'fileutils'

class MingleGrowl
  def initialize mingle_access, state_folder, project
    @mingle_access, @state_folder, @project = mingle_access, state_folder, project
  end

  def growl
    processors = MingleEvents::Processors::Pipeline.new( [
                                                         GrowlPublisher.new
                                                        ])

    processors_by_project = {
      @project => [processors]
    }

    MingleEvents::Poller.new(@mingle_access, processors_by_project, @state_folder).run_once
  end
end

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

