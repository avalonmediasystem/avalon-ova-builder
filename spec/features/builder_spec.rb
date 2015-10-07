require 'spec_helper'
require 'csv'

describe 'Tests for the Builder' do
  let(:buildertester) { Class.new { include Builder } }

  describe 'Tests for the CSV File' do
    before :each do
      remove_csv_and_data_dir
      @builder = buildertester.new
      @builder.make_history_csv
    end

    after :each do
      remove_csv_and_data_dir
    end

    it 'creates a data dir and csv file' do
      expect(File.exist?(@builder.csv_location)).to be_truthy
    end

    it 'creates a new csv file with the headers only' do
      file_content = CSV.read(@builder.csv_location)
      expect(file_content.size).to eq(1)
      expect(file_content[0]).to match_array(@builder.csv_headers)
    end

    it 'returns the file location as a pathname' do
      expect(@builder.csv_location.class).to eq(Pathname)
    end

    it 'returns the headers for the csv as an array of strings' do
      expect(@builder.csv_headers.class).to eq(Array)
      @builder.csv_headers.each do |header|
        expect(header.class).to eq(String)
      end
    end
  end

  describe 'Working with Git Repos' do
    before :all do
      @repo = 'https://github.com/avalonmediasystem/avalon-installer.git'
    end

    it 'clones the git repo' do
      path = buildertester.new.clone_repo(@repo, 'master')
      expect(path.class).to eq(Pathname)
      expect(Dir.exist?(path)).to be_truthy
      FileUtils.rm_rf(path.parent)
    end

    it 'sets the remote branch to master by default' do
      branch = 'flat' # Note: This repo has somewhat fluid branches, so if this
      # fails make sure the branch is still up there on github
      path = buildertester.new.clone_repo(@repo, branch)
      Dir.chdir(path) {
        branch = `git rev-parse --abbrev-ref HEAD`
        expect(branch).to match(branch)
      }
      FileUtils.rm_rf(path.parent)
    end
  end

  describe 'Determing if a build is needed' do
    let(:githubtester) { Class.new { include GithubChecker } }

    avalon_git_api = 'https://api.github.com/repos/avalonmediasystem/avalon/'
    avalon_installer_git_api = 'https://api.github.com/repos/avalonmediasystem/avalon-installer/'
    ova_name = 'OvaFileName.ova'
    success = 'success'
    notes = 'none'

    before :each do
      @builder = buildertester.new
      remove_csv_and_data_dir
    end

    it 'determines a build is needed when there are no builds' do
      VCR.use_cassette('new_build') do
        expect(@builder.ova_already_built?('master')).to be_falsey
      end
    end

    describe 'searching within the csv history file' do
      before :each do
        @builder.make_history_csv
        VCR.use_cassette('build_aready_present') do
          @current_avalon_commit = githubtester.new.get_latest_commit(avalon_git_api, 'master')
          @current_avalon_installer_commit = githubtester.new.get_latest_commit(avalon_installer_git_api, 'master')
        end
      end

      it 'determines a build is not needed when there is already a build for the current branches and commits' do
        VCR.use_cassette('build_aready_present') do
          line = ['master', @current_avalon_commit, 'master', @current_avalon_installer_commit, ova_name, success, notes]
          write_to_history_csv(line)
          expect(@builder.ova_already_built?('master')).to match(ova_name)
        end
      end

      it 'determines a new build is needed if the avalon commits do not match' do
        VCR.use_cassette('build_aready_present') do
          line = ['master', '1', 'master', @current_avalon_installer_commit, ova_name, success, notes]
          write_to_history_csv(line)
          expect(@builder.ova_already_built?('master')).to be_falsey
        end
      end

      it 'determines a new build is needed if the avalon installer commits do not match' do
        VCR.use_cassette('build_aready_present') do
          line = ['master', @current_avalon_commit, 'master', '1', ova_name, success, notes]
          write_to_history_csv(line)
          expect(@builder.ova_already_built?('master')).to be_falsey
        end
      end

      it 'determines a new build is needed if the matching build has failed' do
        VCR.use_cassette('build_aready_present') do
          line = ['master', @current_avalon_commit, 'master', @current_avalon_installer_commit, ova_name, 'failed', notes]
          write_to_history_csv(line)
          expect(@builder.ova_already_built?('master')).to be_falsey
        end
      end
    end
  end

  # Deletes the .csv file and the data dir for cleanup during or after tests
  def remove_csv_and_data_dir
    builder = buildertester.new
    FileUtils.rm_rf(builder.csv_location.dirname) if Dir.exist?(builder.csv_location.dirname)
  end

  def write_to_history_csv(line)
    builder = buildertester.new
    CSV.open(builder.csv_location, 'ab') do |csv|
      csv << line
    end
  end
end
