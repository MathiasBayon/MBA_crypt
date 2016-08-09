# @author Mathias Bayon

require 'crypt/rijndael'
require 'securerandom'
require 'benchmark'
require 'YAML'

# Properties singleton class
class Messages

	# Returns properties.yaml messages
	def self.get()
		@@messages ||= YAML.load_file("properties.yaml")
	end
end

# MBA_crypt class
class MBA_crypt

	# Crypt the file designated by filename
	# @param filename [String] the input file name, which want to encrypt
	def self.crypt(filename, key_length=0)
		# Benchmark is used to monitor encryption duration...
		time = Benchmark.realtime do
			report_and_raise_if_error(:info, Messages::get["encrypt"]["starting"])

			# Check input file
			report_and_raise_if_error(:error, Messages::get["encrypt"]["input_file_does_not_exist"]) unless File.file?(filename)
			report_and_raise_if_error(:error, Messages::get["encrypt"]["imput_file_already_crypted"]) if (filename.end_with?(".MBA_crypt") || filename.end_with?(".MBA_crypt_key"))

			# Generate HEX key
			report_and_raise_if_error(:info, Messages::get["encrypt"]["generating_hex_key"])
			if key_length == 0 # Default
				key_length = File.size(filename)/2
			end
			# Use file size / 2 cause size is in bytes and not HEX
			report_and_raise_if_error(:info, Messages::get["encrypt"]["key_length"]+ "#{key_length} KB")

			key_length /= 2
			key = SecureRandom.hex(key_length)
			
			# Using Rijndael algorithm
			report_and_raise_if_error(:info, Messages::get["encrypt"]["crypting_file"])
			crypt = Crypt::Rijndael.new(key)
			
			# Trigger file encryption in a separate thread
			thr = Thread.new { crypt.encrypt_file(filename, filename+".MBA_crypt") }

			# Write generated random key to key file
			report_and_raise_if_error(:info, Messages::get["encrypt"]["writing_key_to_file"])
			File.open("#{filename}.MBA_crypt_key", 'w') { |file| file.write(key) }

			thr.join
		end

		report_and_raise_if_error(:info, "#{Messages::get["encrypt"]["job_finished..."]} #{time} #{Messages::get["encrypt"]["...seconds"]}")
	end

	# Decrypt the file designated by filename
	# @param filename [String] the input file name, which want to decrypt
	def self.decrypt(filename)
		# Benchmark is used to monitor decryption duration...
		time = Benchmark.realtime do
			report_and_raise_if_error(:info, Messages::get["decrypt"]["starting"])

			# Check input file
			report_and_raise_if_error(:error, Messages::get["decrypt"]["input_file_does_not_exist"]) unless File.file?(filename)
			report_and_raise_if_error(:error, Messages::get["decrypt"]["not_a_MBA_crypt_file"]) unless filename.end_with?(".MBA_crypt")
			
			# Check key file
			key_filename = filename+"_key"
			report_and_raise_if_error(:info, Messages::get["decrypt"]["key_file_does_not_exist"]) unless File.file?(key_filename)

			output_filename = filename.sub(".MBA_crypt", "")
			report_and_raise_if_error(:info, Messages::get["decrypt"]["output_file_already_exists"]) if File.file?(output_filename)

			# Read key from key file
			report_and_raise_if_error(:info, Messages::get["decrypt"]["reading_key_file"])
			key = File.read(key_filename)

			# Using Rijndael algorithm
			report_and_raise_if_error(:info, Messages::get["decrypt"]["decrypting_file"])
			crypt = Crypt::Rijndael.new(key)
			crypt.decrypt_file(filename, output_filename)
		end

		report_and_raise_if_error(:info, "#{Messages::get["decrypt"]["job_finished..."]} #{time} #{Messages::get["decrypt"]["...seconds"]}")
	end

	# Encrypt or decrypt the file designated by filename, depending on file extension
	# @param filename [String] the input file name, which want to encrypt / decrypt
	def self.treat(filename, key_length=0)
		filename.end_with?(".MBA_crypt") ? MBA_crypt.decrypt(filename) : MBA_crypt.crypt(filename, key_length)
	end

	# Log errors to output log
	def self.log_errors
		File.open('MBA_crypt.log', 'w') do |file|
			file.puts "MBA_crypt #{Time.now.inspect} BEGIN"
			
			# Fetch error array
			(Thread.current[:errors] ||= []).each do |error|
				file.puts "\t- "+error
			end
			file.puts "MBA_crypt #{Time.now.inspect} END"

			# Empty error array
			Thread.current[:errors] = []
		end
	end

	private

	# Report message into special array. If message type is :error, then a Runtime Error is raised
	# @param message [String] the message we want to add
	def self.report_and_raise_if_error(type, message)
		(Thread.current[:errors] ||= []) << type.to_s.upcase+" : #{message}"
		raise RuntimeError.new(message) if type == :error
	end

end

# Main
if __FILE__ == $0
	raise "Usage : #{$0} crypt/decrypt <filename>" unless ((ARGV.size) == 2 && ["crypt", "decrypt"].include?(ARGV[0]))

	at_exit { MBA_crypt::log_errors }

	if ARGV[0] == "crypt"
		puts "Crypting #{ARGV[1]}..."
		MBA_crypt::crypt(ARGV[1])
		puts "Done !"
	elsif ARGV[0] == "decrypt"
		puts "Decrypting #{ARGV[1]}..."
		MBA_crypt::decrypt(ARGV[1])
		puts "Done !"
	end
end
