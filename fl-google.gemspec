# -*-ruby-*-

$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "fl/google/version"

Gem::Specification.new do |s|
  s.name        = 'fl-google'
  s.platform    = Gem::Platform::RUBY
  s.version     = Fl::Google::VERSION
  s.date        = Fl::Google::DATE
  s.authors     = [ "Emil Scoffone" ]
  s.email       = 'emil@scoffone.com'
  s.homepage    = 'https://github.com/escoffon/fl-google'
  s.summary     = "Google APIs"
  s.description = "A gem of client code for various Google web service APIs."
  s.license     = 'MIT'

  s.files       = [ 'lib/fl/google.rb', 'lib/fl/google/version.rb',

                    'lib/fl/google/recaptcha.rb',

                    'lib/fl/google/api.rb',

                    'lib/fl/google/api/maps.rb', 'lib/fl/google/api/maps/geocoding.rb',

                    'lib/fl/google/api/v3.rb', 'lib/fl/google/api/v3/base.rb',
                    'lib/fl/google/api/v3/calendar/base.rb', 'lib/fl/google/api/v3/calendar/calendar.rb',
                    'lib/fl/google/api/v3/calendar/channels.rb', 'lib/fl/google/api/v3/calendar/events.rb',
                    'lib/fl/google/api/v3/you_tube/base.rb', 'lib/fl/google/api/v3/you_tube/channel.rb',
                    'lib/fl/google/api/v3/you_tube/playlist_item.rb', 'lib/fl/google/api/v3/you_tube/video.rb',

                    'Rakefile',
                    '.yardopts'
                  ]

  s.add_development_dependency 'minitest'
end
