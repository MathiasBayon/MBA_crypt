# @author Mathias Bayon

require 'gtk3'
require 'tk'

require_relative 'MBA_crypt'

$sub_window_open = false

# global encryption / decryption / logging launcher
# @param filename [String] the input file name
def launch_crypt_decrypt(filename)
	begin
		MBA_crypt::treat(filename)
	rescue
		#Nothing
	end

	MBA_crypt::log_errors
end

# Returns encryption / decryption completion percent
# based on the source file size, compared to the genereted file size (Same size at completion)
# @param filename [String] the input file name
# @return [String] the completion percentage, rounded to XXX.XX digits
def get_operation_completion_percent(filename)
	return (File.size(filename+".MBA_crypt").to_f*100/File.size(filename)).round(2).to_s unless filename.include?(".MBA_crypt") # Crypt
	return (File.size(filename.sub(".MBA_crypt", "")).to_f*100/File.size(filename)).round(2).to_s #Decrypt
end


# TK Main
Gtk.init

window = Gtk::Window.new
window.set_title("MBA crypt")
window.signal_connect('destroy') { Gtk.main_quit }

# Filename entry
filename_entry = Gtk::Entry.new

# Browse files and select button
select_file_button = Gtk::Button.new(:label => 'Select')

# Editor button
create_file_button = Gtk::Button.new(:label => 'New')

# Box for these two buttons, side by side, with the entry path on the left
vbox_files = Gtk::Box.new(Gtk::Orientation::HORIZONTAL, 3)
vbox_files.pack_start(filename_entry, :expand => true, :fill => true)
vbox_files.pack_start(select_file_button, :expand => false, :fill => false)
vbox_files.pack_start(create_file_button, :expand => false, :fill => false)

# Crypt button
crypt_decrypt_button = Gtk::Button.new(:label => 'Crypt / Decrypt!')

# Log pane
label = Gtk::Label.new

# Scrolled pane for logs
scrolled_window = Gtk::ScrolledWindow.new(nil, nil)
scrolled_window.set_policy(Gtk::PolicyType::AUTOMATIC, Gtk::PolicyType::ALWAYS)
scrolled_window.add(label)

# Main box
vbox = Gtk::Box.new(Gtk::Orientation::VERTICAL, 3)

vbox.pack_start(vbox_files, :expand => false, :fill => false)
vbox.pack_start(crypt_decrypt_button, :expand => false, :fill => false)
vbox.pack_start(scrolled_window, :expand => true, :fill => true)

window.add(vbox)
window.set_default_size(400,300);

# Threads
completion_percent_thread, encryption_thread = nil

# Buttons behavious

# Encrypt / Decrypt button
crypt_decrypt_button.signal_connect('clicked') do
	Thread.kill(encryption_thread) unless encryption_thread.nil?
	Thread.kill(completion_percent_thread) unless completion_percent_thread.nil?

	completion_percent_thread = Thread.new do
		while true do
			sleep 1
			label.set_text(get_operation_completion_percent(filename_entry.text)+" %")
			Tk.update
		end
	end

	encryption_thread = Thread.new do
		launch_crypt_decrypt(filename_entry.text)
		File.delete("editor.txt")
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
		entry.text = File.read("editor.txt") if File.exists?("editor.txt")

		ok_button = Gtk::Button.new(:label => 'OK')
		ok_button.signal_connect('clicked') do
			$sub_window_open = false
			File.open(Dir.pwd+"/editor.txt", 'w') { |file| file.write(entry.text) }
			filename_entry.text = Dir.pwd+"/editor.txt"
			sub_window.destroy
		end
		
		quit_button = Gtk::Button.new(:label => 'Quit')
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

		sub_window.set_title("MBA crypt - New file")
		
		sub_window.add(vbox2)
		sub_window.set_default_size(400,300);
		sub_window.show_all
	end
end

# Let's rock!
window.show_all

Gtk.main
