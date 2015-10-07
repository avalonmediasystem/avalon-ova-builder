# githubchecker.rb
require 'json'
require 'rest-client'
require 'retries'

# GithubChecker provides functions for querying Github repositories via the
# github api and determining if the target repo has updated
module GithubChecker
  # Get the latest commit from a specific github repo and branch
  # @param repo [String] The full path to the repo you wish to call
  # @param branch [String] The name of the branch you wish to get the commits to
  # @return [String] A SHA hash of the commit
  def get_latest_commit(repo, branch)
    all_commits = get_commits(repo, branch)
    return all_commits['sha'] # TODO: Extract this key to a config file
  end

  # Gets a list of all commits from the specific github repo and branch
  # @param repo [String] The full path to the repo you wish to call
  # @param branch [String] The name of the branch you wish to get the commits to
  # @return [JSON] A JSON hash of the response from github
  # @example Get all the commits in the Avalon Master Branch
  # get_commits('https://api.github.com/repos/avalonmediasystem/avalon/','master')
  def get_commits(repo, branch)
    # Downcase the strings
    repo.downcase!
    branch.downcase!

    # Make sure we're ending with a trailing / on the repo
    repo << '/' unless repo[repo.size - 1] == '/'

    # The full path for a call is:
    # https://api.github.com/repos/avalonmediasystem/avalon/commits/master/
    # The user may or may not have called with the /commits/ part since we don't
    # specifically require it
    # Determine if it is present, add it if it is not
    commits = 'commits/'
    last_char_pos = repo.size
    repo << commits unless repo[last_char_pos - commits.size..last_char_pos - 1] == commits

    # Use Rest Client to call the Github API and return it as JSON
    api_call = repo + branch
    resp = rest_client_get(api_call)
    return JSON.parse(resp) unless resp.nil?
  end

  # Uses the rest_client gem to get an api_call, retries three times
  # Waits three to ten seconds between tries in case of network errors
  # @param api_call [String]  The call you wish to make
  # @return [String] The response from the call
  def rest_client_get(api_call)
    response = nil
    with_retries(max_tries: 3, rescue: RestClient::Exception,
                 base_sleep_seconds: 3.0, max_sleep_seconds: 10.1) do
      response = RestClient.get api_call
      fail RestClient::Exception if response.nil?
    end
    return response
  end
end
