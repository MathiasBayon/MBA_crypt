# @author Mathias Bayon

require 'gtk3'
require 'tk'
require_relative 'MBA_crypt'
require 'YAML'

$sub_window_open = false

# global encryption / decryption / logging launcher
# @param filename [String] the input file name
def launch_crypt_decrypt(filename, key_length=0)
	begin
		MBA_crypt::treat(filename, key_length)
	rescue
		#Nothing
	end

	MBA_crypt::log_errors
end

def get_selected_key_size(*buttons)
	buttons.each { |button|
		return /(\d+)/.match(button.label).to_s.to_i if button.active?
	}
end

def quit
	File.delete(Messages::get["TK"]["editor_file"]) if File.file?(Messages::get["TK"]["editor_file"])
end

# Returns encryption / decryption completion percent
# based on the source file size, compared to the genereted file size (Same size at completion)
# @param filename [String] the input file name
# @return [String] the completion percentage, rounded to XXX.XX digits
def get_operation_completion_percent(filename)
	return (File.size(filename+".MBA_crypt").to_f/File.size(filename)).round(2) unless filename.include?(".MBA_crypt") # Crypt
	return (File.size(filename.sub(".MBA_crypt", "")).to_f/File.size(filename)).round(2) #Decrypt
end

# Main
if __FILE__ == $0

	# TK Main
	Gtk.init

	window = Gtk::Window.new
	window.set_title("MBA crypt")
	window.signal_connect('destroy') do
		quit
		Gtk.main_quit
	end

	# Filename entry
	filename_entry = Gtk::Entry.new

	# Browse files and select button
	select_file_button = Gtk::Button.new(:label => Messages::get["TK"]["select_button"])

	# Editor button
	create_file_button = Gtk::Button.new(:label => Messages::get["TK"]["new_button"])

	# Box for these two buttons, side by side, with the entry path on the left
	vbox_files = Gtk::Box.new(Gtk::Orientation::HORIZONTAL, 3)
	vbox_files.pack_start(filename_entry, :expand => true, :fill => true)
	vbox_files.pack_start(select_file_button, :expand => false, :fill => false)
	vbox_files.pack_start(create_file_button, :expand => false, :fill => false)

	# Key size radio buttons
	vbox_rb = Gtk::Box.new(Gtk::Orientation::HORIZONTAL, 4)
	label_rb = Gtk::Label.new(Messages::get["TK"]["key_file_size"])
	vbox_rb.pack_start(label_rb, :expand => true, :fill => true)
	button1 = Gtk::RadioButton.new(:label => "512KB")
	vbox_rb.pack_start(button1, :expand => false, :fill => false)
	button2 = Gtk::RadioButton.new(:label => "1024KB", :member => button1)
	vbox_rb.pack_start(button2, :expand => false, :fill => false)
	button3 = Gtk::RadioButton.new(:label => "Filesize", :member => button2)
	vbox_rb.pack_start(button3, :expand => false, :fill => false)

	# Crypt button
	crypt_decrypt_button = Gtk::Button.new(:label => Messages::get["TK"]["crypt_decrypt_button"])

	# Log pane
	label = Gtk::Label.new

	# Scrolled pane for logs
	scrolled_window = Gtk::ScrolledWindow.new(nil, nil)
	scrolled_window.set_policy(Gtk::PolicyType::AUTOMATIC, Gtk::PolicyType::ALWAYS)
	scrolled_window.add(label)

	progress_bar = Gtk::ProgressBar.new

	# Main box
	vbox = Gtk::Box.new(Gtk::Orientation::VERTICAL, 5)

	vbox.pack_start(vbox_files, :expand => false, :fill => false)
	vbox.pack_start(vbox_rb, :expand => false, :fill => false)
	vbox.pack_start(crypt_decrypt_button, :expand => false, :fill => false)
	vbox.pack_start(scrolled_window, :expand => true, :fill => true)
	vbox.pack_start(progress_bar, :expand => false, :fill => false)

	window.add(vbox)
	window.set_default_size(400,300);

	# Threads
	completion_percent_thread = encryption_thread = Thread.new {}

	# Buttons behavious

	# Encrypt / Decrypt button
	crypt_decrypt_button.signal_connect('clicked') do
		Thread.kill(encryption_thread) if encryption_thread.alive?
		Thread.kill(completion_percent_thread) if completion_percent_thread.alive?

		completion_percent_thread = Thread.new do
			while true do
				sleep 1
				label.set_text(Messages::get["TK"]["working"])
				progress_bar.set_fraction(get_operation_completion_percent(filename_entry.text))
				Tk.update
			end
		end

		encryption_thread = Thread.new do
			launch_crypt_decrypt(filename_entry.text, get_selected_key_size(button1, button2, button3)*1024)
			Thread.kill(completion_percent_thread)
			log = File.read("MBA_crypt.log") if File.exists?("MBA_crypt.log")
			label.set_text(log)
		end
		
	end

	# Select file subscreen
	select_file_button.signal_connect('clicked') do
		unless $sub_window_open then
			filename_entry.text = Tk.getOpenFile
		end
		window.present
	end

	# Editor subscreen
	create_file_button.signal_connect('clicked') do
		unless $sub_window_open then
			$sub_window_open = true
			sub_window = Gtk::Window.new

			sub_window.signal_connect('destroy') { $sub_window_open = false }

			entry = Gtk::Entry.new
			entry.text = File.read(Messages::get["TK"]["editor_file"]) if File.exists?(Messages::get["TK"]["editor_file"])

			ok_button = Gtk::Button.new(:label => Messages::get["TK"]["editor_ok_button"])
			ok_button.signal_connect('clicked') do
				$sub_window_open = false
				File.open(Dir.pwd+"/editor.txt", 'w') { |file| file.write(entry.text) }
				filename_entry.text = Dir.pwd+"/"+Messages::get["TK"]["editor_file"]
				sub_window.destroy
			end
			
			quit_button = Gtk::Button.new(:label => Messages::get["TK"]["editor_close_button"])
			quit_button.signal_connect('clicked') do
				$sub_window_open = false
				sub_window.destroy
			end

			vbox = Gtk::Box.new(Gtk::Orientation::HORIZONTAL, 2)
			vbox.pack_start(ok_button, :expand => true, :fill => true)
			vbox.pack_start(quit_button, :expand => false, :fill => false)

			vbox2 = Gtk::Box.new(Gtk::Orientation::VERTICAL, 2)
			vbox2.pack_start(entry, :expand => true, :fill => true)
			vbox2.pack_start(vbox, :expand => false, :fill => false)

			sub_window.set_title(Messages::get["TK"]["editor_title"])
			
			sub_window.add(vbox2)
			sub_window.set_default_size(400,300);
			sub_window.show_all
		end
	end

	# Let's rock!
	window.show_all

	Gtk.main
end
