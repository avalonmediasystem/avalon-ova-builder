require 'spec_helper'

describe "Getting commit info from github" do
  let(:githubtester) { Class.new { include GithubChecker } }
  repo = 'https://api.github.com/repos/avalonmediasystem/avalon/commits/'
  repo_nc = 'https://api.github.com/repos/avalonmediasystem/avalon/'
  master_branch = 'master'

  it "gets a list of commits from github and return them as a JSON object" do
    VCR.use_cassette('get_commits_list') do
      expect(githubtester.new.get_commits(repo, master_branch).class).to eq(Hash)
    end
  end

 it "gets a list of commits from gitub and returns them as a JSON object even without the user supplying commits/ in the URI" do
   VCR.use_cassette('get_commits_list_commits_not_specified') do
     expect(githubtester.new.get_commits(repo_nc, master_branch).class).to eq(Hash)
   end
 end

 it "retries attempts when there is no response" do
     RestClient.should_receive(:get).exactly(3).times
     expect{githubtester.new.rest_client_get('foo/bar')}.to raise_error(RestClient::Exception)
 end

 it "returns the sha key as a string" do
   VCR.use_cassette('get_sha_key_for_master') do
     key = githubtester.new.get_latest_commit(repo, master_branch)
     expect(key.class).to equal(String)
     expect(key).to match('9f1c30db482c7cd709523915f395c830c64a5559')
   end
 end

 it "gets keys from different branches" do
   VCR.use_cassette('get_keys_for_branches') do
     master_key = githubtester.new.get_latest_commit(repo, master_branch)
     develop_key = githubtester.new.get_latest_commit(repo, 'develop')
     expect(master_key.class).to equal(String)
     expect(develop_key.class).to equal(String)
     expect(master_key).to match('9f1c30db482c7cd709523915f395c830c64a5559')
     expect(develop_key).to match('978635f95f1808693505e63525c5dd9065d85551')
   end
 end


end
