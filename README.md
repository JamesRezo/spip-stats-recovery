# My SPIP Stats

The objective of this tool is to recover data from the [SPIP statistics website](https://stats.spip.net/) to process it over time.

## Run

```bash
# Poll & Store changes if any is detected
docker run -v $(pwd):/build spip/stats-poller
```

```bash
# Poll only
docker run -v $(pwd):/build spip/stats-poller poll-only
```

```bash
# Display last poll summary
docker run -v $(pwd):/build spip/stats-poller print
```

```bash
# Compile archives in CSV Files
docker run -v $(pwd):/build spip/stats-poller compile
```

```bash
# Save tthe git repository
docker run -v $(pwd):/build spip/stats-poller -e GIT_AUTHOR_NAME=$(git config --global --get user.name) -e GIT_AUTHOR_EMAIL=$(git config --global --get user.email) save
```
