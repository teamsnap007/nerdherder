# NerdHerder
Automated technical candidate prospect communication and lead generation

## Updating Data

Retroactively change the author name, email etc. BEWARE that doing the following can corrupt your history.
```
#!/bin/sh

git filter-branch --env-filter '

an="$GIT_AUTHOR_NAME"
am="$GIT_AUTHOR_EMAIL"
cn="$GIT_COMMITTER_NAME"
cm="$GIT_COMMITTER_EMAIL"

if [ "$GIT_COMMITTER_EMAIL" = "your@email.to.match" ]
then
    cn="Your New Committer Name"
    cm="Your New Committer Email"
fi
if [ "$GIT_AUTHOR_EMAIL" = "your@email.to.match" ]
then
    an="Your New Author Name"
    am="Your New Author Email"
fi

export GIT_AUTHOR_NAME="$an"
export GIT_AUTHOR_EMAIL="$am"
export GIT_COMMITTER_NAME="$cn"
export GIT_COMMITTER_EMAIL="$cm"
'

```

## Loading Candidate Data

Getting the commit email of a particular user is trivial through the API as explained at: http://stackoverflow.com/a/32456486/895245
Download the query data as explained at: http://stackoverflow.com/questions/18493533/google-bigquery-download-all-data/37274820#37274820

Extract data up to 2014-12-31:

```

SELECT payload_commit_email
FROM [githubarchive:github.timeline]
WHERE type = 'PushEvent'
GROUP BY payload_commit_email
ORDER BY payload_commit_email ASC
Extract data starting from 2015-01-01:
SELECT JSON_EXTRACT(payload, '$.commits')
FROM (
    TABLE_DATE_RANGE([githubarchive:day.events_],
        TIMESTAMP('2015-01-01'),
        TIMESTAMP('2015-01-02')
    ))
WHERE type = 'PushEvent'
TODO: it would have been more intelligent to GROUP BY to only select unique values, and also do more cleaning on the server. Untested:
SELECT JSON_EXTRACT_SCALAR(payload, '$.commits[0].author.email')
    AS email
FROM (
    TABLE_DATE_RANGE([githubarchive:day.events_],
        TIMESTAMP('2015-01-01'),
        TIMESTAMP('2015-01-02')
    ))
WHERE
    type = 'PushEvent'
    AND email <> ''
GROUP BY email
ORDER BY email

```


This would reduce the output size by an order of magnitude.

Clean up a bit if not done on the query:
```
cat * | sed '/^$/d' | sort | uniq > emails-big
```
Merge data from the two queries:
```
sort -u emails-old emails-new > emails-big
```
Split into multiple files:
```
split -a4 -C150k -d emails-big emails/
```
### GitHub limits:
hard limit: 100M per file, larger cannot be pushed
web UI show limit:
TODO file size
1000 files per directory

## Data mining

Count emails:

```
wc -l *
```

Most frequent hostnames:
```
cat * | sed -E 's/.*@(.*)$/\1/' | sort | uniq -c | sort -n | tail -n 1000
```

Some common invalid emails
grep -E '[^0-9a-zA-Z!#$%&'"'"'*+-/=?^_`{|}~@]' * | wc
grep -v '@' * | wc

