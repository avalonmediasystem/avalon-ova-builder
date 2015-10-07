# builder.rb
require 'pathname'
require 'csv'
require 'fileutils'

# This module contains build logic for determining if a new build of the
# Avalon OVA is needed and starting the OVA
module Builder
  # TODO: Move these class variables into a config file and load them from it
  @@csv_headers = %w(avalon_branch avalon_commit avalon_installer_branch
                     avalon_installer_commit 'ova_name build_status notes)
  @@data_dir_location = Pathname(File.dirname(__FILE__) + File::SEPARATOR + 'data' +
                        File::SEPARATOR)
  @@csv_location = Pathname(@@data_dir_location + 'build_history.csv')
  @@avalon_installer_clone_uri = 'https://github.com/avalonmediasystem/avalon-installer.git'
  @@default_avalon_installer_branch = 'master'

  # Makes the history CSV for avalon builds, creates the directory and .csv file
  # if they currently do not exist and writes in a stub .csv file with just the
  # headers
  def make_history_csv
    FileUtils.mkdir_p(@@csv_location.dirname) unless Dir.exist?(csv_location.dirname)
    create_stub_csv_file unless File.exist?(@@csv_location)
  end

  # Creates a stub CSV file with just the headers, will overwrite any current
  # .csv that is in place
  def create_stub_csv_file
    File.rm(@@csv_location) if File.exist?(@@csv_location)
    CSV.open(@@csv_location, 'w') do |row|
      row << @@csv_headers
    end
  end

  # Helper to return the CSV location
  # @return [Pathname] The location of the file
  def csv_location
    return @@csv_location
  end

  # Helper to return the CSV Headers
  # @return [Array<String>]  The headers
  def csv_headers
    return @@csv_headers
  end

  # Clones a selected git repo and checks out the specificed branch from origin
  # @param repo [String]  The clone url for the git repo
  # @param branch [String] (default: master) The branch of the repo to checkout
  # @return [Pathname] The path where the git repo was cloned
  def clone_repo(repo, branch = 'master')
    # For the destination, stick it in a timestamped dir so if multiple builds
    # are going on, each has their own spot
    checkout_destination = Pathname(@@data_dir_location.to_s + (Time.now.utc.to_s + File::SEPARATOR))
    repo_name = Pathname(repo).basename.to_s.split('.')[0]
    repo_path = Pathname(checkout_destination.to_s + repo_name + File::SEPARATOR)
    FileUtils.mkdir_p(checkout_destination)
    Dir.chdir(checkout_destination) {
      system("git clone #{repo}")
    }
    checkout_branch(repo_path, branch) unless branch.downcase.eql? 'master'
    return repo_path
  end

  # Checkouts the indicated branch from origin
  #
  # @param repo_path [Pathname]  The location of the repo
  # @param branch [String] The name of the remote branch you want to checkout
  def checkout_branch(repo_path, branch)
    Dir.chdir(repo_path) {
      system('git fetch')
      system("git checkout #{branch}")
    }
  end





end
