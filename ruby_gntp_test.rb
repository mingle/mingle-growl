require 'rubygems'
require 'ruby_gntp'

# -- Standard way
growl = GNTP.new("Ruby/GNTP self test")
growl.register({:notifications => [{
  :name     => "notify",
  :enabled  => true,
}]})

growl.notify({
  :name  => "notify",
  :title => "Congraturation",
  :text  => "Congraturation! You are successful install ruby_gntp.",
  :icon  => "http://www.hatena.ne.jp/users/sn/snaka72/profile.gif",
  :sticky=> true
})

# -- Instant notification
GNTP.notify({
  :app_name => "Instant notify",
  :title    => "Instant notification",
  :text     => "Instant notification available now.",
  :icon     => "http://www.hatena.ne.jp/users/sn/snaka72/profile.gif",
})
