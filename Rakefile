#!/usr/bin/env ruby
# -*- ruby -*-

# @author Mathias Bayon

require 'rake'
require 'rspec/core/rake_task'
require_relative 'MBA_crypt'
require_relative 'MBA_crypt_TK'

task :default => :run

task :run do
	ruby "MBA_crypt_TK.rb"
end

task :crypt do
	at_exit { MBA_crypt::log_errors }
	filename_crypt = ""

	while filename_crypt.empty? do
		puts "Enter file name :"
		filename_crypt = STDIN.gets.chomp
	end

	MBA_crypt.crypt(filename_crypt)
end

task :decrypt do
	at_exit { MBA_crypt::log_errors }
	filename_decrypt = ""

	while filename_decrypt.empty? do
		puts "Enter file name :"
		filename_decrypt = STDIN.gets.chomp
	end

	puts MBA_crypt.decrypt(filename_decrypt)
end

task :spec do
	puts "Runnign RSpec task..."
 	RSpec::Core::RakeTask.new(:spec)
end

task :clean do
	File.delete(*Dir.glob('./*.MBA_crypt'))
	File.delete(*Dir.glob('./*.MBA_crypt_key'))
end
