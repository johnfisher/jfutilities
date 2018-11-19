#!/bin/bash
cd /var/www/repo
rsync -avz * build@10.2.1.20:/backup/localrepo
