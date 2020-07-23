require 'octokit'
require 'json'
require 'time'
require 'fileutils'

#Check source
def check_source(source_config, source_key)
  begin
    source_config.fetch(source_key)
  rescue  KeyError => e
    abort("No '#{source_key}' key found, malformed json input!")
  end
end

#Check required params
def check_required_params(source_config)
  required_params = ["repo", "comment_regex", "github_token"]

  required_params.each do |param|
    begin
      source_config.fetch(param)
    rescue KeyError => e
      abort("Required parameter '#{param}' not given")
    end
  end
end

#Validate repo name
def validate_repo_name(repo_name)
  begin
    raise ArgumentError.new("Repo name is invalid. Pattern: ^([^/]+)/?([^/]+)$") if !repo_name.match(/^([^\/]+)\/?([^\/]+)$/)
  rescue ArgumentError => e
    abort(e.message)
  end
end

#Validate comment regex
def validate_comment_regex(regex)
  begin
    raise ArgumentError.new("Regex is invalid. Pattern: ^([^/]+)/?([^/]+)$") if !regex.match(/^((\/).+)\/?(.*(\/))$/)
  rescue ArgumentError => e
    abort(e.message)
  end
end

def get_pr_comments(repo, github_token, since)

  $comments = []

  client = Octokit::Client.new :access_token => github_token

  options = {
      :sort => 'asc',
      :direction => 'asc',
      :since => since
  }

  begin
    client.issues_comments(repo, options).each do |pr_comment|
      comment = pr_comment[:body].to_s
      id = pr_comment[:id].to_s
      created = pr_comment[:created_at].utc.iso8601.to_s
      issue_url = pr_comment[:issue_url].to_s
      $comments.push({ 'id' => id,  'comment' => comment, 'created' => created, 'issue_url' => issue_url})
    end
  rescue StandardError => e
    abort(e.message)
  end
end

def generate_check_output(repo, github_token, comment_regex, current_version)
  $versions = []
  # if it's a first check then get all comments for the last 10 mins, if no comments return default version
  first_check = current_version ? false : true
  default_version = { 'id' => '0',  'comment' => '', 'created' => Time.parse((Time.new).to_s).utc.iso8601}
  version = !first_check ? current_version : default_version

  if first_check
    since = Time.parse((Time.new-10*60).to_s).utc.iso8601
  else
    since = (Time.parse(version["created"])+1).utc.iso8601
  end

  get_pr_comments(repo, github_token, since)

  $comments.each do |comment|
    #Get only the latest comment with matched regex
    if comment["comment"].match(eval(comment_regex))
      version = {
          'id' => comment["id"],
          'comment' => comment["comment"],
          'created' => comment["created"],
          'issue_url' => comment["issue_url"]
      }
      $versions.push(version)
    end
  end

  if $versions.length == 0
    $versions.push(version)
  end

end

def check_dest_directory_arg
  begin
    raise ArgumentError.new("No destination directory was provided!") if ARGV[0].nil?
  rescue ArgumentError => e
    abort(e.message)
  end
end

def create_destination_file
  dest_dir = ARGV[0]
  FileUtils.mkdir_p dest_dir
  $dest_comment = File.join(dest_dir, "comment")
  $dest_issue_url = File.join(dest_dir, "issue_url")
end

def generate_in_output(source, dest_file_comment, dest_file_issue_url)
  version = source["version"]
  comment = version["comment"].split.join(" ")
  issue_url = version["issue_url"]

  File.open(dest_file_comment, 'w') { |file| file.write(comment) }
  File.open(dest_file_issue_url, 'w') { |file| file.write(issue_url) }

  metadata = []
  metadata.push({"name" => "comment", "value" => comment})
  metadata.push({"name" => "issue_url", "value" => issue_url})

  output = {"version" => version, "metadata" => metadata}

  puts output.to_json
end

def generate_out_output(source)
  version = source["version"]
  metadata = []

  output = {"version" => version, "metadata" => metadata}
  puts output
  STDERR.puts "Resource doesn't support 'out' action"
end
