# My SPIP Stats

The objective of this tool is to recover data from the [SPIP statistics website](https://stats.spip.net/) to process it over time.

## Run

```bash
# Poll & Store changes if any is detected
docker run -v $(pwd):/build jamesrezo/myspipnetstats
```

```bash
# Poll only
docker run -v $(pwd):/build jamesrezo/myspipnetstats poll-only
```

```bash
# Display last poll summary
docker run -v $(pwd):/build jamesrezo/myspipnetstats print
```
