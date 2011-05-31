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
    event.categories.include? MingleEvents::Category::PROPERTY_CHANGE and return GrowlCardChanged.new event
    event.categories.include? MingleEvents::Category::CARD_CREATION and return GrowlCardCreated.new event
    event.categories.include? MingleEvents::Category::NAME_CHANGE and return GrowlNameChanged.new event
  end

  class GrowlCardCreated
    def initialize event
      @event = event
    end

    def notify
      GNTP.notify({
                    :app_name => "Mingle Growl",
                    :title    => title,
                    :text     => text
                 })
    end

    private
    def title
      @event.title
    end

    def text

    end
  end

  class GrowlCardChanged
    def initialize event
      @event = event
    end

    def notify
      GNTP.notify({
                    :app_name => "Mingle Growl",
                    :title    => title,
                    :text     => text
                 })
    end

    private
    def title
      @event.title
    end

    def text
      "#{change.name} changed from #{change.old_value} to #{change.new_value}"
    end

    def change
      @event.changes.first
    end
  end

  class GrowlNameChanged
    def initialize event
      @event = event
    end

    def notify
      GNTP.notify({
                    :app_name => "Mingle Growl",
                    :title    => title,
                    :text     => text
                 })
    end

    private
    def title
      @event.title
    end

    def text

    end

  end
end

