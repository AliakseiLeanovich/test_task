# encoding: utf-8

require 'active_support/all'
require 'net/sftp'
require 'iconv'
require 'csv'

require_relative './transaction_builder'

SERVER_URL =
  if Rails.env == 'production'
    'csv.example.com/endpoint/'
  else
    '0.0.0.0:2020'
  end
SFTP_PARAMS = [SERVER_URL, 'some-ftp-user', keys: ['path-to-credentials']].freeze

class CsvExporter
  extend TransactionBuilder

  @errors = []
  cattr_accessor :import_retry_count

  class << self
    def transfer_and_import(send_email = true)
      @errors = []

      local_files = transfer_from_remote
      import_from_local_files(local_files, send_email)
    end

    def transfer_from_remote
      build_local_folders
      local_files = []
      Net::SFTP.start(*SFTP_PARAMS) do |sftp|
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
      FileUtils.mkdir_p "#{Rails.root}/private/data"
      FileUtils.mkdir_p "#{Rails.root}/private/data/download"
    end

    def available_entries(sftp)
      remote_files = sftp.dir.entries('/data/files/csv').map(&:name)
      remote_files.select do |filename|
        filename[-4, 4] == '.csv' &&
          remote_files.include?(filename + '.start')
      end.sort
    end

    private

    def upload_error_file(entry, result)
      FileUtils.mkdir_p "#{Rails.root}/private/data/upload"
      error_file = "#{Rails.root}/private/data/upload/#{entry}"
      File.open(error_file, 'w') do |f|
        f.write(result)
      end
      Net::SFTP.start(*SFTP_PARAMS) do |sftp|
        sftp.upload!(error_file, "/data/files/batch_processed/#{entry}")
      end
    end
  end
end
