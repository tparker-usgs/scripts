#!/usr/bin/env python
#
# I waive copyright and related rights in the this work worldwide
# through the CC0 1.0 Universal public domain dedication.
# https://creativecommons.org/publicdomain/zero/1.0/legalcode
#
# Author(s):
#   Tom Parker <tparker@usgs.gov>
#

""" Retrieve avo webcam images from FTP server. """

from ftplib import FTP
from datetime import timedelta, datetime
import logging
import os.path
import shutil
import re

FTP_HOST = os.environ['FTP_HOST']
FTP_USER = os.environ['FTP_USER']
FTP_PASSWD = os.environ['FTP_PASSWD']
FTP_TIMEOUT = float(os.environ['FTP_TIMEOUT'])
TMP_DIR = os.environ['TMP_DIR']
OUT_DIR = os.environ['OUT_DIR']

ONE_DAY = timedelta(days=1)

CAM_DATE = re.compile(r'^(.*)-(\d{8}_\d{4})(\..*)$')

def get_dir(ftp, remote_dir=''):
    """ return a list of files in a directory """

    lines = []
    ftp.retrlines('LIST ' + remote_dir, lines.append)

    files = []
    for line in lines:
        files.append(line.split()[-1])

    return files


def get_path(image):
    """ provide a formated path given a file name """

    matcher = CAM_DATE.match(image)
    cam = matcher.group(1)
    date = matcher.group(2)
    #date = image[-17:-4]
    #cam = image[:-18]

    image_date = datetime.strptime(date, '%Y%m%d_%H%M')
    image_name = datetime.strftime(image_date, '%Y/%m/%d')

    return os.path.join(cam, image_name)

def discover_images(ftp, cam):
    """ find new images in a cam directory """

    images = []

    for image in get_dir(ftp, cam):
        matcher = CAM_DATE.match(image)
        if not matcher:
            continue
        outpath = get_path(image)
        if outpath:
            out_image = os.path.join(OUT_DIR, outpath, image)
            if not os.path.exists(out_image):
                images.append('/'.join([cam, image]))

    return images


def fetch_image(ftp, image_path):
    """ retrieve a single image """

    logging.info("Fetching %s", image_path)
    image = os.path.basename(image_path)
    tmp_file = os.path.join(TMP_DIR, image)

    image_handle = open(tmp_file, 'wb')
    ftp.retrbinary('RETR ' + image_path, image_handle.write)
    image_handle.close()

    out_dir = os.path.join(OUT_DIR, get_path(image))
    if not os.path.exists(out_dir):
        os.makedirs(out_dir)

    out_file = os.path.join(out_dir, image)
    logging.debug("moving %s -> %s", tmp_file, out_file)
    shutil.move(tmp_file, out_file)


def main():
    """ mirror a directory of cam images """

    ftp_conn = FTP(FTP_HOST, FTP_USER, FTP_PASSWD, timeout=FTP_TIMEOUT)

    cams = get_dir(ftp_conn)
    for cam in cams:
        logging.info("Found cam %s", cam)
        last_image = ""
        for image in discover_images(ftp_conn, cam):
            fetch_image(ftp_conn, image)
            last_image = image

        matcher = CAM_DATE.match(os.path.basename(last_image))
        if matcher:
            link = os.path.join(OUT_DIR, matcher.group(1) + matcher.group(3))
            image = os.path.join(OUT_DIR,
                                 get_path(os.path.basename(last_image)),
                                 os.path.basename(last_image))
            logging.info("linking %s -> %s", image, link)
            if os.path.exists(link):
                logging.info("removing %s", link)
                os.unlink(link)
            else:
                logging.info("LINK DOESNT EXIST %s", link)

            os.symlink(image, link)

    ftp_conn.quit()

    cam_file_name = os.path.join(OUT_DIR, "cams.txt")
    cam_file = open(cam_file_name, "wb")
    cam_file.write("\n".join(cams))
    cam_file.close()

logging.basicConfig(level=logging.DEBUG)
if __name__ == "__main__":
    main()
