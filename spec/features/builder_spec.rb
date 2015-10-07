require 'spec_helper'

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

  # Deletes the .csv file and the data dir for cleanup during or after tests
  def remove_csv_and_data_dir
    builder = buildertester.new
    FileUtils.rm_rf(builder.csv_location.dirname) if Dir.exist?(builder.csv_location.dirname)
  end
end
