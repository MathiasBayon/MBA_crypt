# MBA_crypt
Little Ruby/TK file crypting application (using crypt gem)

Start
- Use .bat file to start application, using Windows
- Use "rake" to start application using Linux / OSX
- You may also trigger encrypt/decrypt from command line, using "rake crypt <file>" or "rake decrypt <file>"

Use
- Click "Select file" button to open file browser, then select a file
- You can also use the little embedded editor, which will create an editor.txt file (Deleted after encryption)
- If the file extension is .MBA_crypt, then clicking "Crypt / Decrypt!" button will trigger file decrypt
- If the file extension is not .MBA_crypt, then clicking "Crypt / Decrypt!" button will trigger file encryption
- Wait for the load indicator to reaach 100%, then displays the output log, and its done!
- The encrypted / decrypted file will appear in the same folder as the source file
- A key file is generated. It must be present in the same folder as the encrypted file to allow file decrypt
- Key file is automatically generated during encryption
- Key file has the same length as source file
- Rijndael algorithm is used, provided by crypt gem, it is very slow
