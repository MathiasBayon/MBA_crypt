# @author Mathias Bayon

require 'crypt/rijndael'
require 'securerandom'
require 'benchmark'

class MBA_crypt

	# Crypt the file designated by filename
	# @param filename [String] the input file name, which want to encrypt
	def self.crypt(filename)
		# Benchmark is used to monitor encryption duration...
		time = Benchmark.realtime do
			report_and_raise_if_error("INFO : Encryption job starting...")

			# Check input file
			report_and_raise_if_error("ERROR : Input file does not exist") unless File.file?(filename)
			report_and_raise_if_error("ERROR : Input file already crypted, or key file") if (filename.end_with?(".MBA_crypt") || filename.end_with?(".MBA_crypt_key"))

			# Generate HEX key (Use file size / 2 cause size is in bytes and not HEX)
			report_and_raise_if_error("INFO : Generating HEX key...")
			key = SecureRandom.hex(File.size(filename)/2)
			
			# Using Rijndael algorithm
			report_and_raise_if_error("INFO : Crypting file...")
			crypt = Crypt::Rijndael.new(key)
			
			# Trigger file encryption in a separate thread
			thr = Thread.new { crypt.encrypt_file(filename, filename+".MBA_crypt") }

			# Write generated random key to key file
			report_and_raise_if_error("INFO : Writing key to file...")
			File.open("#{filename}.MBA_crypt_key", 'w') { |file| file.write(key) }

			thr.join
		end

		report_and_raise_if_error("INFO : Job finished in #{time} seconds.")
	end

	# Decrypt the file designated by filename
	# @param filename [String] the input file name, which want to decrypt
	def self.decrypt(filename)
		# Benchmark is used to monitor decryption duration...
		time = Benchmark.realtime do
			report_and_raise_if_error("INFO : Decryption job starting...")

			# Check input file
			report_and_raise_if_error("ERROR : Input file does not exist") unless File.file?(filename)
			report_and_raise_if_error("ERROR : Not a MBA_crypt file") unless filename.end_with?(".MBA_crypt")
			
			# Check key file
			key_filename = filename+"_key"
			report_and_raise_if_error("ERROR : Key file does not exists") unless File.file?(key_filename)

			output_filename = filename.sub(".MBA_crypt", "")
			report_and_raise_if_error("ERROR : Output file already exists") if File.file?(output_filename)

			# Read key from key file
			report_and_raise_if_error("INFO : Reading key file...")
			key = File.read(key_filename)

			# Using Rijndael algorithm
			report_and_raise_if_error("INFO : Decrypting file...")
			crypt = Crypt::Rijndael.new(key)
			crypt.decrypt_file(filename, output_filename)
		end

		report_and_raise_if_error("INFO : Job finished in #{time} seconds.")
	end

	# Encrypt or decrypt the file designated by filename, depending on file extension
	# @param filename [String] the input file name, which want to encryot / decrypt
	def self.treat(filename)
		filename.end_with?(".MBA_crypt") ? MBA_crypt.decrypt(filename) : MBA_crypt.crypt(filename)
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

	# Report message into special array. If message contains "ERROR", then a Runtime Error is raised
	# @param message [String] the message we want to add
	def self.report_and_raise_if_error(message)
		(Thread.current[:errors] ||= []) << "#{message}"
		raise RuntimeError.new(message) if message.include?("ERROR")
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
