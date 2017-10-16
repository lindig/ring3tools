#! /bin/sh
# list clone URLs of all repositories of a GitHub organisation
# this requires the jq(1) JSON processor

org=${1:-"xapi-project"}

# The REST interface returns pages or results. Find out how many.
pages()
{
 sed -n 's/^Link:.*page=\([0-9][0-9]*\)>; rel="last".*$/\1/p'
}

n="$(curl -sI "https://api.github.com/orgs/$org/repos" | pages)"

seq 1 "$n" | while read p; do
  curl -s "https://api.github.com/orgs/$org/repos?page=$p"
done | jq -rs 'add|map(.clone_url)|.[]'
