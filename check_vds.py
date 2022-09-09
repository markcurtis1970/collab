#!/usr/bin/env python3

'''
The following script will get all views and then iterate over them to grab the catalog and path info
'''

import requests, time
import sys

# Check arguments
def usage():
    # (note 2 includes arg 0 which is this script!)
    if len(sys.argv) != 2:
        print ('\n***',sys.argv[0], '***\n')
        print ('Incorrect number of arguments, please run script as follows:')
        print ('\n'+str(sys.argv[0])+' hostname:port')
        sys.exit(0)

# Setup vars / read files etc
def setup_env():
    global ip
    ip = sys.argv[1]

# Authentication
def auth():
    global auth_header, authorization_code, BASE_URL
    BASE_URL = 'http://' + ip 
    headers = {
        'Content-Type': 'application/json',
    }
    data = '{"userName": "mc", "password": "dremio123"}'
    response = requests.post(BASE_URL + '/apiv2/login', headers=headers, data=data, verify=False)
    if response.status_code == 200:
        print ('Successfully authenticated.')
    else:
        print('Authentication failed.')
        sys.exit(1)
    authorization_code = '_dremio' + response.json()['token'] # _dremio is prepended to the token
    auth_header = {
        'Authorization': authorization_code,
        'Content-Type': 'application/json',
    }


# Get all VDS
def get_views():
    global views
    data = '{"sql": "SELECT * FROM INFORMATION_SCHEMA.views"}'
    response = requests.post(BASE_URL + '/api/v3/sql', headers=auth_header, data=data)
    
    # Validate response
    if response.status_code == 200:
        job_id = response.json()['id']
        print ('Job creation successful. Job id is: ' + job_id)
    else:
        print('Job creation failed.')
        sys.exit(1)

    # Get status of the previous job
    print('Waiting for the job to complete...')
    job_status = requests.request("GET", BASE_URL + "/api/v3/job/" +job_id, headers=auth_header).json()['jobState']
    while job_status != 'COMPLETED':
        time.sleep(1)
        job_status = requests.request("GET", BASE_URL + "/api/v3/job/" +job_id, headers=auth_header).json()['jobState']
    
    # Get the results from the job
    response = requests.request("GET", BASE_URL + "/api/v3/job/"+job_id+"/results", headers=auth_header)
    # Validate response
    if response.status_code == 200:
        print ('Results fetched ok')
    else:
        print('Results fetch failed')
        sys.exit(1)
    views=response.json()


def main():
    usage()
    setup_env()
    auth()
    get_views()

if __name__ == "__main__":
    main()
