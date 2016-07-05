# @author Mathias Bayon

require_relative '../MBA_crypt'

RSpec.describe MBA_crypt do
    before(:each) do
        # Nothing for the moment...
    end

    # tests related to file checkings
    describe "Filer" do
        it "should not be able to crypt a non existing file" do
            expect { MBA_crypt::crypt("non_existing_filename").to raise_error(RuntimeError, /Input file does not exist/) }
        end

        it "should not be able to decrypt a non existing file" do
            expect { MBA_crypt::decrypt("non_existing_filename").to raise_error(RuntimeError, /Input file does not exist/) }
        end

        it "should not be able to decrypt a non MBA_crypt file" do
            File.open("test_file", 'w') { |file| file.write("Hello World") }
            expect { MBA_crypt::decrypt("test_file").to raise_error(RuntimeError, /Not a MBA_crypt file/) }
            File.delete("test_file")
        end

        it "should not be able to crypt an already MBA_crypted file" do
            File.open("test_file.MBA_crypt", 'w') { |file| file.write("Gibberish") }
            expect { MBA_crypt::crypt("test_file").to raise_error(RuntimeError, /Input file already crypted, or key file/) }
            File.delete("test_file.MBA_crypt")
        end

        it "should not be able to crypt a key file" do
            File.open("test_file.MBA_crypt_key", 'w') { |file| file.write("Gibberish") }
            expect { MBA_crypt::crypt("test_file").to raise_error(RuntimeError, /Input file already crypted, or key file/) }
            File.delete("test_file.MBA_crypt_key")
        end

        it "should not be able to decrypt a file without key file" do
            File.open("test_file.MBA_crypt", 'w') { |file| file.write("Gibberish") }
            expect { MBA_crypt::decrypt("test_file.MBA_crypt").to raise_error(RuntimeError, /Key file does not exists/) }
            File.delete("test_file.MBA_crypt")
        end

        it "should not be able to erase a file when decrypting" do
            File.open("test_file.MBA_crypt", 'w') { |file| file.write("Gibberish") }
            File.open("test_file.MBA_crypt_key", 'w') { |file| file.write("Key") }
            File.open("test_file", 'w') { |file| file.write("Hello World") }
            expect { MBA_crypt::decrypt("test_file.MBA_crypt").to raise_error(RuntimeError, /Output file already exists/) }
            File.delete("test_file.MBA_crypt")
            File.delete("test_file.MBA_crypt_key")
            File.delete("test_file")
        end    
    end

    # tests related to file encryption / decryption
    describe "Encrypter / Decrypter" do
        it "should be able to decrypt a file with the encryption key" do
            File.open("test_file", 'w') { |file| file.write("Hello World !") }
            MBA_crypt::crypt("test_file")
            File.delete("test_file")
            MBA_crypt::decrypt("test_file.MBA_crypt")
            file_content = File.read("test_file")
            expect { file_content.to eq "Hello World !" }
            File.delete("test_file.MBA_crypt")
            File.delete("test_file.MBA_crypt_key")
        end

        it "should NOT be able to decrypt a file with a bad encryption key" do
            File.open("test_file", 'w') { |file| file.write("Hello World !") }
            MBA_crypt::crypt("test_file")
            File.delete("test_file")
            File.open("test_file.MBA_crypt_key", 'w') { |file| file.write("Bad key") }
            MBA_crypt::decrypt("test_file.MBA_crypt")
            file_content = File.read("test_file")
            expect { file_content.to eq "Hello World !" }
            File.delete("test_file.MBA_crypt")
            File.delete("test_file.MBA_crypt_key")
            File.delete("test_file")
        end
    end

end