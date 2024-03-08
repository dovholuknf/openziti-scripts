import base64
import json
import requests
from datetime import datetime

def make_censys_request(url, params, api_id, api_secret):
    credentials = f"{api_id}:{api_secret}"
    encoded_credentials = base64.b64encode(credentials.encode('utf-8')).decode('utf-8')
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Basic {encoded_credentials}'
    }

    print(f"Making request to {url}")
    print(f"Headers: {headers}")
    print(f"Params: {params}")

    response = requests.get(url, params=params, headers=headers)

    print(f"Response: {response.status_code}")
    print(f"Response Content: {response.json() if response.headers['Content-Type'] == 'application/json' else response.text}")

    return response


def process_result(result):
    # Process each result (customize as needed)
    print(json.dumps(result, indent=2))


def process_censys_data(current_date, api_id, api_secret, search, q, cursor=None):
    url = "https://search.censys.io/api/v2/hosts/search"

    # Parameters for the Censys query
    params = {
        'per_page': 100,
        'virtual_hosts': 'EXCLUDE',
        'sort': 'RELEVANCE',
        "cursor": cursor,
        'q': q
    }

    response = make_censys_request(url, params, api_id, api_secret)

    if response.status_code == 200:
        try:
            content_type = response.headers['Content-Type']
            if 'application/json' in content_type:
                result = response.json()
                total = result.get('result', {}).get('total', 0)
                print(f"Number of hits: {total}")

                with open(current_date + "." + search + ".json", "a") as output_file:
                    output_file.write(json.dumps(result) + "\n")

                next_link = result.get('result', {}).get('links', {}).get('next')
                if next_link:
                    print("Next Link exists. Processing next page.")
                    cursor = result.get('result', {}).get('links', {}).get('next')
                    process_censys_data(current_date, api_id, api_secret, search, q, cursor=cursor)
                else:
                    print("No 'next' link. Exiting.")
            else:
                print(f"Unexpected content type: {content_type}")
        except Exception as e:
            print(f"Error processing response: {e}")
    else:
        print(f"Error: {response.status_code}, {response.text}")


if __name__ == "__main__":
    # Read credentials from a file named censys.env
    with open("censys.env", "r") as file:
        for line in file:
            parts = line.strip().split("=")
            if len(parts) == 2:
                key, value = parts
                if key == "CENSYS_API_ID":
                    api_id = value
                elif key == "CENSYS_API_SECRET":
                    api_secret = value
        current_date = datetime.now().strftime("%Y-%m-%d")
        query = (
            "(services.http.response.headers.Server: ziti-controller "
            "or services.http.response.html_title: \"Open Ziti Console\" "
            "or services.http.response.html_title: \"Ziti Admin Console\" "
            "or services.http.response.html_title: \"Ziti Login\" "
            "or services.tls.certificates.leaf_data.issuer_dn:\"OU=ADV-DEV\" "
            "or services.tls.certificates.leaf_data.issuer.organizational_unit:\"ADV-DEV\" "
            "or services.http.response.headers: (key:\"X-Ziti-BrowZer\")) "
            "and not services.tls.certificates.leaf_data.names:\"netfoundry.io\""
            #" and not services.port: {22}"
            #" and not services.transport_protocol: \"udp\""
        )
        nfquery = (
            "services.tls.certificates.leaf_data.names:\"netfoundry.io\""
            #" and not services.port: {22}"
            #" and not services.transport_protocol: \"udp\""
        )

        process_censys_data(current_date, api_id, api_secret, "censys-data", query)
        process_censys_data(current_date, api_id, api_secret, "censys-data-nf", nfquery)
        #process_censys_data(current_date, api_id, api_secret, "censys-ziti-controller", "services.http.response.headers.Server: ziti-controller and not services.tls.certificates.leaf_data.names:\"netfoundry.io\"")
        #process_censys_data(current_date, api_id, api_secret, "censys-zac", "services.http.response.html_title: \"Open Ziti Console\" or services.http.response.html_title: \"Ziti Admin Console\" or services.http.response.html_title: \"Ziti Login\"")
        #process_censys_data(current_date, api_id, api_secret, "censys-ziti-routers", "(services.tls.certificates.leaf_data.issuer_dn:\"OU=ADV-DEV\" or services.tls.certificates.leaf_data.issuer.organizational_unit:\"ADV-DEV\") and not (services.http.response.headers.Server: ziti-controller and not services.tls.certificates.leaf_data.names:\"netfoundry.io\") and not (services.http.response.html_title: \"Open Ziti Console\" or services.http.response.html_title: \"Ziti Admin Console\" or services.http.response.html_title: \"Ziti Login\")")
        #process_censys_data(current_date, api_id, api_secret, "censys-browzer-bootstrappers", "services.http.response.headers: (key:\"X-Ziti-BrowZer\")")
        
