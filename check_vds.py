#!/usr/bin/env python3

'''
The following script will get all views and then iterate over them to grab the catalog and path info
'''

import requests, time, json
import sys
import os

# Check arguments
def usage():
    # (note 2 includes arg 0 which is this script!)
    if len(sys.argv) != 2:
        print ('\n***',sys.argv[0], '***\n')
        print ('Incorrect number of arguments, please run script as follows:')
        print ('\n'+str(sys.argv[0])+' hostname:port')
        sys.exit(0)

# Setup vars etc
def setup_env():
    global ip, opt
    ip = sys.argv[1]
    opt = "vds_query.json"
    


# Authentication
def auth():
    global auth_header, authorization_code, BASE_URL
    BASE_URL = 'http://' + ip 
    headers = {
        'Content-Type': 'application/json',
    }
    data = '{"userName": "dremio", "password": "dremio123"}'
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
    global job, job_id
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
    
    # Once job is successful then continue or error
    if job_status == 'COMPLETED':
        job = requests.request("GET", BASE_URL + "/api/v3/job/" +job_id, headers=auth_header).json()
    else:
        print('Job ' + job_id + ' exited with status ' + job['jobState'])
        sys.exit(1)

# Page thru results
def page_results():
    global views
    # Cycle through all results
    res = 0
    views = {}
    limit=10
    while res < int(job['rowCount']):
        response = requests.request("GET", BASE_URL + "/api/v3/job/"+job_id+"/results?offset=" + str(res) + "&limit=" + str(limit), headers=auth_header)
        print("GET", BASE_URL + "/api/v3/job/"+job_id+"/results/offset=" + str(res) + "&limit" + str(limit))
        # Validate response
        if response.status_code == 200:
            print ('Results fetched from '+ str(res) + " to " + str(res + limit))
            res = res + limit
            if len(views)==0:
               views.update(response.json())
            else:
               for row in response.json()['rows']:
                   views['rows'].append(row)
        else:
            print('Results fetch failed for '+ str(res) + " to " + str(res + limit))
            sys.exit(1)


# Catalog query
def get_catalog():
    global catalog_ids
    catalog_ids=[]
    for row in views['rows']:
        schema = str(row["TABLE_SCHEMA"]).replace(".", "/")
        table = str(row["TABLE_NAME"])
        path = schema + '/' + table
        print('Fetching catalog for dataset: ' + path)
        catalog_resp = requests.request("GET", BASE_URL + "/api/v3/catalog/by-path/" + path, headers=auth_header)
        # Validate response
        if catalog_resp.status_code == 200:
            json_resp=json.dumps(catalog_resp.json())
            f.write(str(json_resp) + "\n")
            catalog_ids.append(catalog_resp.json()['id'])
        else:
            print('Catalog error:', catalog_resp.status_code, catalog_resp.text)
        #    sys.exit(1) # choose wether or not to abort on error


# Graph query
def get_graph():
    for catalog_id in catalog_ids:
        print('Fetching graph for dataset id: ' + catalog_id)
        graph_resp = requests.request("GET", BASE_URL + "/api/v3/catalog/" + catalog_id + "/graph", headers=auth_header)
        # Validate response
        if graph_resp.status_code == 200:
            json_resp=json.dumps(graph_resp.json())
            f.write(str(json_resp) + "\n")
        else:
            print('Catalog error:', graph_resp.status_code, graph_resp.text)
        #    sys.exit(1) # choose wether or not to abort on error

# Get VDS Catalog info
def get_catalog_debug():
    print(type(views))
    print(views["rows"])
    for row in views["rows"]:
        path = '"' + str(row["TABLE_SCHEMA"]) + '"/"' + str(row["TABLE_NAME"]) + '"'
        print(path)
        


def main():
    global f
    usage()
    setup_env()
    auth()
    f = open(opt, "x")
    f.close
    f = open(opt, "a")
    get_views()
    page_results()
    get_catalog()
    get_graph()
    print("Results in: " + opt)
    f.close

if __name__ == "__main__":
    main()
