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

process the censys data by calling the discover script. if you don't pass a date
it'll assume today's date. alternatively you can pass a date in yyyy-mm-dd format:
```
python3 discover-oz-components.py
```

Assuming today was 2024-03-08, when done you'll be left with two more files that 
have been processed which will also be ignored via .gitignore:
```
2024-03-08.censys-data.results.txt
2024-03-08.censys-data-nf.results.txt
```

process those files however you see fit.