# builder.rb
require 'pathname'
require 'csv'
require 'fileutils'
require 'GithubChecker'

# This module contains build logic for determining if a new build of the
# Avalon OVA is needed and starting the OVA
module Builder
  # TODO: Move these class variables into a config file and load them from it
  @@csv_headers = %w(avalon_branch avalon_commit avalon_installer_branch
                     avalon_installer_commit ova_name build_status notes)
  @@build_success = 'success'
  @@build_failed = 'failed'
  @@data_dir_location = Pathname(File.dirname(__FILE__) + "#{File::SEPARATOR}data#{File::SEPARATOR}")
  @@csv_location = Pathname(@@data_dir_location + 'build_history.csv')
  @@avalon_installer_clone_uri = 'https://github.com/avalonmediasystem/avalon-installer.git'
  @@default_avalon_installer_branch = 'master'
  @@avalon_installer_github_api =  'https://api.github.com/repos/avalonmediasystem/avalon-installer/'
  @@avalon_github_api = 'https://api.github.com/repos/avalonmediasystem/avalon/'

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

  # Initialzes an OVA Build and records the results to build_history.csv
  #
  # @param installer_branch [String] (default: master) The branch of the ova
  # installer to be used
  # @param force_rebuild [Boolean] (default: False) If a build for the avalon
  # and avalon-installer already exists, this determines if it should be rebuilt
  def build_ova(installer_branch = 'master', force_rebuild = false)
    build_dir = clone_repo(@@avalon_installer_clone_uri, installer_branch)
    current_installer_commit = 'foo'
  end

  # Determines if we already have an ova using the passed installer branch
  # and the master branch of avalon
  #
  # @param installer_branch [String] The installer branch to check against
  # @return [Boolean] False if there is not a build
  # @return [String] The path to the ova if there is one present
  def ova_already_built?(installer_branch)
    make_history_csv #only creates one if there isn't one
    git_check_class = Class.new { include GithubChecker }
    git_check = git_check_class.new
    current_installer_commit = git_check.get_latest_commit(@@avalon_installer_github_api, installer_branch)
    current_avalon_commit = git_check.get_latest_commit(@@avalon_github_api, @@default_avalon_installer_branch)
    search = {'avalon_branch' => @@default_avalon_installer_branch, 'avalon_commit' => current_avalon_commit, 'avalon_installer_branch' => installer_branch, 'avalon_installer_commit' => current_installer_commit, 'build_status' => @@build_success}
    CSV.open(@@csv_location, 'r', :headers => true) do |csv|
      csv.find_all do |row|
        match = true
        search.keys.each do |key|
          match &&= row[key].eql? search[key]
        end
        return row['ova_name'] if match
      end
    end
    return false
  end
end
