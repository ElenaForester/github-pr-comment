# Concourse Github pull request comment resource
Concourse resource to trigger a job from Github issue comment.

## Source configuration
- `repo`: (*required*) The github repo `<org>/<repo>`
- `comment_regex`: (*required*) Which regex to lookup in comments. Example `"/^(T|t)est it/"`
- `github_token`: Token for authentication

## Behaviour
### `check`
It checks for all comments were published since the last check and gets the latest one which matches the regex.
If no version is given then it gets all comments for the last 10 mins, if no comments returns default version.

### `in`
Places the following files in the destination:

- `metadata.json`: Contains the comment content and its issue url
- `version`: A file containing the version
- `comment`: Contains the comment content
- `issue_url`: Contains the issue url where comment was added

### `out`
Resource doesn't support `out` action

## Example
Resource configuration
```yaml
resource_types:
- name: pr-comment-resource
    type: docker-image
    source:
      repository: elenaforester/github-pr-comment
      tag: 0.0.1

resources:
- name: pr-comment
type: pr-comment-resource
source:
    repo: elenaforester/testrepo
    comment_regex: "/^(T|t)est it/"
    github_token: <github_token>

jobs:
- name: test-job
  plan:
  - get: pr-comment
    trigger: true
    version: every
```
