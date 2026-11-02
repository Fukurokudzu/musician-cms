# frozen_string_literal: true

namespace :admin do
  desc "Change the admin password. Usage: rails admin:set_password[new_pass] (or omit the arg to be prompted)"
  task :set_password, [:password] => :environment do |_task, args|
    password = args[:password] || ENV["ADMIN_PASSWORD"]

    if password.blank?
      abort "Not a terminal, pass the password as an argument or via ADMIN_PASSWORD" unless $stdin.tty?

      require "io/console"
      print "New admin password: "
      password = $stdin.noecho(&:gets).to_s.chomp
      puts
    end

    Auth.change_password!(password)
    puts "Admin password updated"
  end
end
