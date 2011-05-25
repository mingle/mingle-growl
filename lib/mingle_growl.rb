require 'rubygems'
require 'mingle_events'
require 'fileutils'

# specify mingle access
mingle_access = MingleEvents::MingleBasicAuthAccess.new(
  'http://localhost:8080',
  'mira',
  'mira'
)

# construct event processing pipelines
stdout = MingleEvents::Processors::Pipeline.new([
  MingleEvents::Processors::PutsPublisher.new
])

# assign processors to project
processors_by_project = {
  'xmail' => [stdout]
}

# specify where to store event processing state
state_folder = File.dirname('bookmark')

# run the poller once.  you'll want to schedule this with cron or something similar
MingleEvents::Poller.new(mingle_access, processors_by_project, state_folder).run_once

