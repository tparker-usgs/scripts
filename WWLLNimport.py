#!/usr/bin/env python

"""Import WWLLN lightning data into Valve."""

import argparse
import json
from time import mktime
from datetime import timedelta, date
import re
import logging
import cStringIO
import os

import MySQLdb
import dateutil.parser  # aka python-dateutil
import xmltodict
import pycurl

J2KOFFSET = -946728000

MYSQL_USER = os.environ['VDX_USER']
MYSQL_PASS = os.environ['VDX_PASS']
MYSQL_HOST = os.environ['VDX_HOST']
MYSQL_DB = os.environ['VDX_DB']

WWLLN_URL = os.environ['WWLLN_URL']
WWLLN_PATTERN = r'href="(.*\.kml)"'

# 2012-12-16T00:38:60Z
WWLLN_BAD_DATE = re.compile(r'(.{16}):60Z')


TMP_DIR = "/tmp/"

class ImportLightning(object):
    """Import WWLLN data into Valave.

    Import WWLLN data into Valve. If requested, retrieve a list of KML files
    from WWLLN and import each file. Otherwise, import KML files provided on the
    command line.
    """

    def __init__(self):
        """Open connection to database.

        """

        self._connection = MySQLdb.connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASS,
                                           MYSQL_DB)
        self._cursor = self._connection.cursor()

    def _insert_stroke(self, stroke):
        """Insert a single stroke into the Valve MySQL database."""

        sql = ("REPLACE INTO strokes (j2ksec, lat, lon, stationsDetected,"
               " residual) VALUES ( %(j2ksec)s, %(lat)s, %(lon)s,"
               " %(stationsDetected)s, %(residual)s )" % stroke)
        logging.debug("SQL: %s", sql)
        self._cursor.execute(sql)
        self._connection.commit()

    def _import_file(self, filename):
        """Import strokes from a KML file into Valve"""

        logging.debug("importing %s", filename)
        with open(filename, 'r') as myfile:
            data = myfile.read().replace('\n', '')

        strokes = parse_kml(data)

        for stroke in strokes:
            self._insert_stroke(stroke)

    def import_files(self, files):
        """Import a list of files from the local filesystem."""

        for filename in files:
            self._import_file(filename)

    def import_web(self, imp_date=""):
        """Import a collection of files from the WWLLN web site."""

        if len(imp_date) > 0:
            resource = 'archive/' + imp_date + '/'
        else:
            resource = ''
        logging.debug("importing WWLLN files from %s", resource)
        for kml_file in get_wwlln_list(resource):
            kml_file = get_wwlln_file(resource + kml_file)
            self._import_file(kml_file)
            os.remove(kml_file)


def get_wwlln_file(filename):
    """Retrieve a single KML file from WWLLN."""

    path = TMP_DIR + os.path.basename(filename)
    url = WWLLN_URL + "/" + filename
    logging.debug("Pulling %s to %s", url, path)
    with open(path, 'wb') as fileh:
        curl = pycurl.Curl()
        curl.setopt(curl.URL, url)
        curl.setopt(curl.WRITEDATA, fileh)
        curl.setopt(pycurl.CONNECTTIMEOUT, 5)
        curl.setopt(pycurl.TIMEOUT, 5)

        curl.perform()
        logging.info(url + ' -> ' + path)

    return path


def get_wwlln_list(resource=''):
    """Scrape a WWLLN web page for KML files."""

    logging.debug("Getting file list from %s", resource)
    buf = cStringIO.StringIO()
    curl = pycurl.Curl()
    curl.setopt(curl.URL, WWLLN_URL + resource)
    curl.setopt(curl.WRITEFUNCTION, buf.write)
    curl.perform()

    files = re.findall(WWLLN_PATTERN, buf.getvalue())
    logging.debug("Got files: " + str(files))
    buf.close()

    return files


def timestamp_to_j2ksec(timestamp):
    """Convert a timstamp string into a J2KSec"""

    matcher = WWLLN_BAD_DATE.match(timestamp)
    offset = J2KOFFSET
    if matcher:
        offset += 1
        timestamp = matcher.group(1) + ":59Z"

    #pylint: disable=maybe-no-member
    return mktime(dateutil.parser.parse(timestamp).timetuple()) + offset


def arg_parse():
    """Parse command line arguments."""

    parser = argparse.ArgumentParser()
    parser.add_argument("-v", "--verbose",
                        help="Verbose logging",
                        action='store_true')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-d", "--import_date", help="import a collection of "
                       "files for a specific date provided in yyyymmdd format")
    group.add_argument("-f", "--import_files", help="import a list of files",
                       action="store_true")
    group.add_argument("-w", "--import_web",
                       help="import current kml files from WWLLN",
                       action="store_true")
    group.add_argument("-y", "--yesterday_web",
                       help="import eysterdays kml files from WWLLN",
                       action="store_true")
    parser.add_argument("files", nargs=argparse.REMAINDER)
    return parser.parse_args()


def create_stroke(event):
    """Create a stroke object from an event dict."""

    stroke = {}
    stroke['j2ksec'] = timestamp_to_j2ksec(event["name"])
    print event["name"] + " -> " + str(stroke['j2ksec'])
    stroke_coord = event["Point"]["coordinates"]
    stroke_lon, stroke_lat = stroke_coord.split(',')
    stroke['lon'] = stroke_lon
    stroke['lat'] = stroke_lat

    description = event["description"]

    pattern = re.compile(r'.*detected at (\d+) WWLLN stations.*')
    num_detected = pattern.match(description).group(1)
    stroke['stationsDetected'] = num_detected

    pattern = re.compile(r'.*Residual: ([\d\.]+) .*')
    residual = pattern.match(description).group(1)
    stroke['residual'] = residual

    return stroke


def parse_kml(kml):
    """Parse a single KML file."""

    events = xmltodict.parse(kml)["kml"]["Document"]["Folder"]["Folder"]
    logging.debug("JSON: %s", json.dumps(events[0], indent=2))
    strokes = []

    for count in range(2):
        if 'Placemark' not in events[count]:
            continue

        elif type(events[count]["Placemark"]) is list:
            for event in events[count]["Placemark"]:
                strokes.append(create_stroke(event))

        else:
            strokes.append(create_stroke(events[count]["Placemark"]))

    return strokes


def main():
    """Where it all begins."""

    args = arg_parse()
    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)

    level = logging.getLogger().getEffectiveLevel()
    print "Logging level " + logging.getLevelName(level)

    avo_lightning = ImportLightning()

    if args.import_files:
        avo_lightning.import_files(args.files)
    elif args.import_web:
        avo_lightning.import_web()
    elif args.yesterday_web:
        yesterday = (date.today() - timedelta(1)).strftime('%Y%m%d')
        avo_lightning.import_web(yesterday)
    elif args.import_date:
        avo_lightning.import_web(args.import_date)


if __name__ == '__main__':
    main()
