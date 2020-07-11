# My SPIP Stats

The objective of this tool is to recover data from the [SPIP statistics website](https://stats.spip.net/) to process it over time.

## Run

```bash
# Poll
docker run -v $(pwd):/build jamesrezo/myspipnetstats
```

```bash
# Store changes if any is detected
docker run -v $(pwd):/build jamesrezo/myspipnetstats archive
```
