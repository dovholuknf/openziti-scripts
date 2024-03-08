# Usage

to run the censys query, you'll need to define `censys.env`

```
censys.env
CENSYS_API_ID=__id__
CENSYS_API_SECRET=__secret__
```

run the censys query:
```
python3 censys.query.py
```

This will produce two files which are .gitignore'ed by `censys-data`
```
2024-03-08.censys-data.json
2024-03-08.censys-data-nf.json
```

process the censys data:
```
python3 discover-oz-components.py 2024-03-08.censys-data
python3 discover-oz-components.py 2024-03-08.censys-data-nf
```

you'll be left with two more files that have been processed which will also be ignored:
```
2024-03-08.censys-data.results.txt
2024-03-08.censys-data-nf.results.txt
```

process those files however you see fit