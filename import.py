'''
Load address points into postgres
'''

import json
import os
import psycopg2

def process(cursor, addresses):
    '''
    Load points into postgres table
    '''
    for address in addresses:
        address_id = address['id']
        for point in address['addresses']:
            cursor.execute('INSERT INTO points VALUES ('
                           '%(id)s, %(address)s, ST_SetSRID(ST_POINT(%(lon)s, %(lat)s), 4326))', {
                               'id': address_id,
                               'address': point['address'],
                               'lat': point['latitude'],
                               'lon': point['longitude']
                           })


if __name__ == '__main__':
    db_conn = psycopg2.connect(
        host=os.environ['PGHOST'],
        port=os.environ['PGPORT'],
        database=os.environ['PGDATABASE'],
        user=os.environ['PGUSER'],
        password=os.environ['PGPASSWORD'])
    _cursor = db_conn.cursor()
    with open('addresses.json') as fh:
        _points = json.load(fh)
    process(_cursor, _points)
    db_conn.commit()
