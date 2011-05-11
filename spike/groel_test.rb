require 'rubygems'
require 'groem'

app = Groem::App.new('Downloader', :host => 'localhost')

app.register do
  icon 'http://www.example.com/icon.png'
  header 'X-Custom-Header', 'default value'

  # notification with callback expected
  notification :finished, 'Your download has finished!' do |n|
    n.sticky = 'True'
    n.text = 'Run it!'
    n.icon 'path/to/local/icon.png'  #=> generate x-growl-resource (future)
    n.callback 'process', :type => 'run'
  end

  # notification with no callback
  notification :started, 'Your download is starting!',
  :display_name => 'Downloader working'

end


