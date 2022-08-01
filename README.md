# NerdHerder
Automated technical candidate prospect communication and lead generation

-----------

Millions of GitHub commit emails "leaked"

https://github.com/cirosantilli/all-github-commit-emails extracted from GitHub Archives https://www.githubarchive.org exports commit.

GitHub Archive gets data from GitHub's events API: https://developer.github.com/v3/activity/events/types/#pushevent and exports it to Google BigQuery hourly which makes it easier to query.

Practical way to get someone's commit email with the API
```
ghmail() { curl "https://api.github.com/users/$1/events/public" | grep email; }
ghmail peteralcock

```

or visit: https://api.github.com/users/peteralcock/events/public


-----------

## About

Create an email marketing plan for particular group on GitHub, collect addresses fromepository you want, 
and then send email content to those email addresses.

### Installation

```bash
pip install github-email-explorer
```

There are two commends can be used in github-email-explorer,

* ```ge-explore```: Get email address list from stargazers, forks or watchers on a repository
* ```ge-sendgrid```: Send email by list or repository name with SendGrid API

SendGrid is only one email provider at current progress.

### Example of Getting Email Addresses from Stargazers, Forks or Watchers

#### A. Using Command

```bash
$ ge-explore --repo yuecen/github-email-explorer --action_type star fork watch
 
John (john2) <John@example.org>; Peter James (pjames) <James@example.org>;
```

You can get user email by ```ge-explore``` with ```<owner>/<repo>```. The email 
addresses are responded in a formatted string. You can copy contact list to any 
email service you have, then send your email with those contact address.

(If you encounter the situation of limitation from GitHub server during running 
the command, please add ```--client_id <your_github_auth_id> --client_secret <your_github_auth_secret>``` 
with the command above. Get *Client ID* and *Client Secret* by [OAuth applications].)

#### B. Using Python Script

```python
from github_email_explorer import github_email

ges = github_email.collect_email_info('yuecen', 'github-email-explorer', ['star', 'watch'])

for ge in ges:
    print ge.g_id, "->", ge.name, ",", ge.email

# With Authentication
# github_api_auth = ('<your_client_id>', '<your_client_secret>')
# ges = github_email.collect_email_info('yuecen', 'github-email-explorer', ['star', 'watch'],
#                                        github_api_auth=github_api_auth)
```

```bash
$ python examples/get_email.py

0john123 -> P.J. John, john@example.org
pjames56 -> Peter James, james@example.org
```

You can find get_email.py in *examples* folder.

### How to Send a Email to GitHub Users from a Particular Repository?

#### 1. Write Email Content with Template Format

The [Jinja2] is used to render email content and basic template [expressions] make email content more flexible for personal information.

Here is an example to use following syntax, the file saved to ```examples/marketing_email.txt```

```
subject: We LOVE your code in {{repository}}... Wanna grab a drink? ;)
from: hr@teamsnap.com
user: peteralcock
repository: peteralcock/nerdherder
repository_owner: peteralcock
repository_name: nerdherder
site: GitHub

<p>Hi {{ user.name }} ({{ user.g_id }}),</p>
<p>Thank you for making {{ repository_owner }}/{{ repository_name }}!</p>

<p>...</p>

<p>I look forward to seeing you on GitHub :)</p>
<p>peteralcock</p>
```

| Metadata Field  | Description   |
| --------------- |:------------- |
| subject         | email subject |
| from            | sender address|
| from_name       | sender name   |
| user            | you can put an email list with a well format for parse user's ```name``` and ```g_id```. For example, ```John (john2) <John@example.org>; Peter James (pjames) <James@example.org>```. If you don't put an email list, the repository field will be used for running ge-explore to get email list. |
| repository      | full repository name on GitHub|
| repository_owner| repository owner |
| repository_name | repository name  |

```site``` is not a essential field, it will be in SendGrid custom_args field for log

You can use syntax ```{{ ... }}``` to substitute metadata field in runtime stage for personal information.

#### 2. Send Email

In order to send email to many users flexibly, we combine the email list from 
result of ge-explore and SendGrid to approach it.

```
ge-sendgrid --api_key <your_sendgrid_api_key> 
            --template_path ($pwd)/examples/marketing_email.txt
```

### More...

In order to understand API [rate limit] you are using, the status information 
can be found by github-email-explorer command.

Without authentication

```bash
$ ge-explore --status

Resource Type      Limit    Remaining  Reset Time
---------------  -------  -----------  --------------------
Core                  60           60  2016-07-07T04:56:12Z
Search                10           10  2016-07-07T03:57:12Z
```

With authentication

You can request more than 60 using authentication by [OAuth applications]

```bash
$ ge-explore --status --client_id <your_github_auth_id> --client_secret <your_github_auth_secret>

== GitHub API Status ==
Resource Type      Limit    Remaining  Reset Time
---------------  -------  -----------  --------------------
Core                5000         5000  2016-07-06T07:59:47Z
Search                30           30  2016-07-06T07:00:47Z
```


[rate limit]:https://developer.github.com/v3/rate_limit/
[OAuth applications]:https://github.com/settings/developers
[Jinja2]:http://jinja.pocoo.org/
[expressions]:http://jinja.pocoo.org/docs/dev/templates/#expressions




## Updating Bulk Archieve Data

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

