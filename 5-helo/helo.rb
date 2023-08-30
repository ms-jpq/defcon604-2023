#!/usr/bin/env -S -- ruby
# frozen_string_literal: true

script = File.absolute_path(__FILE__)
Dir.chdir(__dir__)

puts("HELO :: VIA -- #{File.basename(__FILE__)}")
system('bat', script, exception: true)
