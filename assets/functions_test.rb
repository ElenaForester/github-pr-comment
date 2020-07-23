require_relative 'functions'
require 'test/unit'

class ValidateInputs < Test::Unit::TestCase
  def test_check_source
    missing_version_source = JSON.parse('{
      "source": {
        "github_token": "this_is_a_token",
        "repo": "test/repo",
        "comment_regex": "/^(T|t)est comment/"
      }
    }')

    assert_raise(SystemExit) {check_source(missing_version_source, "version")}
    assert_raise_message("No 'version' key found, malformed json input!") {check_source(missing_version_source, "version")}
  end

  def test_check_required_params
    missing_repo_source_source = JSON.parse('{
      "source": {
        "github_token": "this_is_a_token",
        "comment_regex": "/^(T|t)est comment/"
      }
    }')

    assert_raise(SystemExit) {check_required_params(missing_repo_source_source)}
    assert_raise_message("Required parameter 'repo' not given") {check_required_params(missing_repo_source_source)}
  end

  def test_check_validate_repo_name
    invalid_repo_source_source = JSON.parse('{
      "source": {
        "github_token": "this_is_a_token",
        "repo": "/test/repo",
        "comment_regex": "/^(T|t)est comment/"
      }
    }')

    assert_raise(SystemExit) {validate_repo_name(invalid_repo_source_source["source"]["repo"])}
    assert_raise_message("Repo name is invalid. Pattern: ^([^/]+)/?([^/]+)$") {validate_repo_name(invalid_repo_source_source["source"]["repo"])}
  end

  def test_validate_comment_regex
    invalid_comment_regex_source_source = JSON.parse('{
      "source": {
        "github_token": "this_is_a_token",
        "repo": "test/repo",
        "comment_regex": "^(T|t)est comment/"
      }
    }')

    assert_raise(SystemExit) {validate_comment_regex(invalid_comment_regex_source_source["source"]["comment_regex"])}
    assert_raise_message("Regex is invalid. Pattern: ^([^/]+)/?([^/]+)$") {validate_comment_regex(invalid_comment_regex_source_source["source"]["comment_regex"])}
  end

  def test_get_pr_comments
    wrong_github_token_source = JSON.parse('{
      "source": {
        "github_token": "this_is_a_wrong_token",
        "repo": "elenaforester/github-pr-comment",
        "comment_regex": "/^(T|t)est comment/"
      }
    }')

    since = "2020-07-23T12:37:26Z"
    error_message = "GET https://api.github.com/repos/elenaforester/github-pr-comment/issues/comments?direction=asc&since=" + CGI.escape(since) + "&sort=asc: 401 - Bad credentials // See: https://developer.github.com/v3"

    assert_raise(SystemExit) {get_pr_comments(wrong_github_token_source["source"]["repo"], wrong_github_token_source["source"]["github_token"], since)}
    assert_raise_message(error_message) {get_pr_comments(wrong_github_token_source["source"]["repo"], wrong_github_token_source["source"]["github_token"], since)}
  end
end
