# OpenALTO Image

Build the docker image for a fork of FTS3:

> FTS3 Fork: https://github.com/fno2010/fts3/tree/zero-order-grad

```
docker build -t alto/fts3-container .
```

## Change Log from Source Repo

- Not pass table name through soci::use

- Insert default values to DB schema

- Update DB schema default charset to utf8

- Add full DB schema dump

- Read TCN data structures from DB

- Allow project level resource control

    Considered Jacob's proposal.

    Signed-off-by: jensenzhang <hack@jensen-zhang.site>

- Change throughput computation and monitoring

    Add `bool timeMultiplexing` to `getPairState` to determine how to
    compute throughput.

    Change `TCNDefaultBWLimit` from `int64_t` MB/s to `double` KB/s.

    Signed-off-by: jensenzhang <hack@jensen-zhang.site>

- Pass all active pipes to optimizer

    Signed-off-by: jensenzhang <hack@jensen-zhang.site>

- Define config variables

    Signed-off-by: jensenzhang <hack@jensen-zhang.site>

- Make parameters configurable

    Signed-off-by: jensenzhang <hack@jensen-zhang.site>