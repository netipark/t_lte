#!/usr/bin/python
#
# Copyright (C) 2018 EUCAST Co, Ltd. - http://www.eu-cast.com/
#

import os
import sys
import logging
import time
import os.path
import crypt
import spwd
import urllib
import csv
import datetime

WWW_LOG_DIR = '/var/log/www/'
WWW_USER_DATA = '/srv/www/data/user.csv'

usr = 'root'
pw = 'root'
unquote_pw='' # to accept the escpaed charactres
username = 'admin'
user=[["root",0,0,0],["puser",0,0,0],["none",0,0,0]]
 
def update_user(username, verified):
    global user
    curTime=time.time()
    for i in range(0, 3):
        if username == user[i][0]:
            user[i][1]=int(curTime)
            if verified == True:
                user[i][2]=1
                user[i][3]=0
            else:
                user[i][2]=0
                user[i][3]=int(user[i][3])+1
            break

    f = open(WWW_USER_DATA, 'w')
    wr = csv.writer(f, delimiter=',')
    for i in range(0, 3):
        wr.writerow([user[i][0], user[i][1], user[i][2], user[i][3]])
    f.close()

def read_user():
    i = 0
    if not os.path.exists(WWW_USER_DATA):
        update_user('none', True)

    try:
        f = open(WWW_USER_DATA, 'r')
        rdr = csv.reader(f, delimiter=',')
        for line in rdr:
            user[i][0] = line[0] # username
            user[i][1] = line[1] # last login time
            user[i][2] = line[2] # verified
            user[i][3] = line[3] # login fail count
            i=i+1
        f.close()

    except:
        f.close()
        update_user('none',True);

def check_locked(username):
    global user
    curTime = time.time()
    for i in range(0, 3):
        if username == user[i][0]:
            if int(user[i][3]) < 5:
                if (int(curTime) - int(user[i][1])) > 600:
                    update_user(username, True)
                return False
            if (int(curTime) - int(user[i][1])) < 600:
                return True
    return False

def check_login(username):
    global user
    curTime = time.time()
    for i in range(0, 3):
        if username == user[i][0]:
            if int(user[i][2]) == 1:
                if (int(curTime) - int(user[i][1])) < 300:
                    return True
    return False
