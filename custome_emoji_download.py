#!/usr/bin/env python
# coding: utf-8

import requests
import json
import tarfile
import os
import click
import re


@click.command()
@click.argument('domain')
def main(domain):
    custom_emojis_api = 'https://' + domain + "/api/v1/custom_emojis"
    resp = requests.get(custom_emojis_api, timeout=15)
    emojis = resp.json()

    tar = tarfile.open(domain + '_emoji.tar.gz','w:gz')
    if not os.path.exists(os.path.join('/tmp','emoji_download')):
        os.mkdir(os.path.join('/tmp','emoji_download'))

    for emoji in emojis:
        shortcode = emoji['shortcode']
        url = emoji['url']
        try:
            resp = requests.get(url, timeout=15)
        except:
            continue

        url_end = os.path.splitext(url)[-1]
        suffix = re.sub('\?\w+$','',url_end)
        file_name = shortcode + suffix
        tmp_file = os.path.join('/tmp', 'emoji_download', file_name)
        with open(tmp_file,'wb') as f:
            f.write(resp.content)
        tar.add(tmp_file,arcname=file_name)    

    tar.close()


if __name__ == '__main__':
    main()

