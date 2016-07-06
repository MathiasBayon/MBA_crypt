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

filename = Gtk::Entry.new
label = Gtk::Label.new

thr2, thr = nil

crypt_decrypt_button = Gtk::Button.new(:label => 'Crypt / Decrypt!')
crypt_decrypt_button.signal_connect('clicked') do
	Thread.kill(thr) unless thr.nil?
	Thread.kill(thr2) unless thr2.nil?

	thr2 = Thread.new do
		while true do
			sleep 1
			label.set_text(get_operation_completion_percent(filename.text)+" %")
			Tk.update
		end
	end

	thr = Thread.new do
		launch_crypt_decrypt(filename.text)
		File.delete("editor.txt")
		Thread.kill(thr2)
		log = File.read("MBA_crypt.log") if File.exists?("MBA_crypt.log")
		label.set_text(log)
	end
	
end

select_file_button = Gtk::Button.new(:label => 'Select file')
select_file_button.signal_connect('clicked') do
	unless $sub_window_open then
		filename.text = Tk.getOpenFile
	end
	window.present
end

scrolled_window = Gtk::ScrolledWindow.new(nil, nil)
scrolled_window.set_policy(Gtk::PolicyType::AUTOMATIC, Gtk::PolicyType::ALWAYS)
scrolled_window.add(label)

vbox = Gtk::Box.new(Gtk::Orientation::VERTICAL, 4)

create_file_button = Gtk::Button.new(:label => 'New')
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
			filename.text = Dir.pwd+"/editor.txt"
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

vbox2 = Gtk::Box.new(Gtk::Orientation::HORIZONTAL, 2)
vbox2.pack_start(filename, :expand => true, :fill => true)
vbox2.pack_start(create_file_button, :expand => false, :fill => false)

vbox.pack_start(vbox2, :expand => false, :fill => false)
vbox.pack_start(select_file_button, :expand => false, :fill => false)
vbox.pack_start(crypt_decrypt_button, :expand => false, :fill => false)
vbox.pack_start(scrolled_window, :expand => true, :fill => true)

window.add(vbox)
window.set_default_size(400,300);

window.show_all

Gtk.main
