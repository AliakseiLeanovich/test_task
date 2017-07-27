# encoding: utf-8
require 'net/sftp'
require 'iconv'
require 'csv'

require_relative './transaction_builder'

class CsvExporter
  extend TransactionBuilder

  @sftp_server = Rails.env == 'production' ? 'csv.example.com/endpoint/' : '0.0.0.0:2020'
  @errors = []

  cattr_accessor :import_retry_count

  def self.transfer_and_import(send_email = true)
    @errors = []

    local_files = transfer_from_remote
    import_from_local_files(local_files, send_email)
  end

  class << self
    def transfer_from_remote
      build_local_folders
      local_files = []
      Net::SFTP.start(@sftp_server, "some-ftp-user", :keys => ["path-to-credentials"]) do |sftp|
        sftp_entries = available_entries(sftp)
        sftp_entries.each do |entry|
          sftp.download!(remote_path(entry), local_path(entry))
          sftp.remove!(remote_path(entry) + '.start')

          local_files << entry
        end
      end
      local_files
    end

    def build_local_folders
      FileUtils.mkdir_p "#{Rails.root.to_s}/private/data"
      FileUtils.mkdir_p "#{Rails.root.to_s}/private/data/download"
    end

    def available_entries(sftp)
      remote_files = sftp.dir.entries("/data/files/csv").map{ |e| e.name }
      remote_files.select do |filename|
        filename[-4, 4] == '.csv' &&
        remote_files.include?(filename + '.start')
      end.sort
    end
  end

  private

  def self.upload_error_file(entry, result)
    FileUtils.mkdir_p "#{Rails.root.to_s}/private/data/upload"
    error_file = "#{Rails.root.to_s}/private/data/upload/#{entry}"
    File.open(error_file, "w") do |f|
      f.write(result)
    end
    Net::SFTP.start(@sftp_server, "some-ftp-user", :keys => ["path-to-credentials"]) do |sftp|
      sftp.upload!(error_file, "/data/files/batch_processed/#{entry}")
    end
  end
end
