cd "$(dirname "$0")"
python3 censys.query.py
python3 discover-oz-components.py
