# frozen_string_literal: true

require 'uri'
require 'net/ftp'

def env_has_key(key)
  !ENV[key].nil? && ENV[key] != '' ? ENV[key] : abort("Missing #{key}.")
end

def login(server_address, username, password)
  uri = URI.parse(server_address)
  port = uri.port || 21
  ftp = Net::FTP.new
  ftp.connect(uri.host, port)
  ftp.login(username, password)
  ftp
rescue StandardError => e
  raise "Login failed with error: #{e}"
end

def upload_to_ftp_server(server_address, username, password, local_path, remote_path)
  ftp = login(server_address, username, password)
  ftp.chdir(remote_path)

  if File.directory?(local_path)
    upload_directory(ftp, local_path)
  else
    upload_file(ftp, local_path)
  end
  ftp.close
end

def upload_directory(ftp, local_path)
  Dir.entries(local_path).each do |file|
    next if ['.', '..'].include? file

    file_path = "#{local_path}/#{file}"
    if File.directory?(file_path)
      ftp.mkdir(file) unless ftp.nlst.index(file)
      ftp.chdir(file)
      upload_directory(ftp, file_path)
      ftp.chdir('..')
    else
      upload_file(ftp, "#{local_path}/#{file}", file)
    end
  end
end

def upload_file(ftp, local_path, filename = nil)
  puts " [-] Uploading #{local_path}"
  if filename.nil?
    ftp.putbinaryfile(local_path)
  else
    ftp.putbinaryfile(local_path, filename)
  end
end

server_address = env_has_key('AC_FTP_HOST')
username = env_has_key('AC_FTP_USER')
password = env_has_key('AC_FTP_PASS')
local_path = env_has_key('AC_FTP_SOURCE')
remote_path = env_has_key('AC_FTP_TARGET')

puts "[+] Server Address #{server_address}"
upload_to_ftp_server(server_address, username, password, local_path, remote_path)
puts '[+] Upload finished.'
