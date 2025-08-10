#!/usr/bin/env -S uv run --script
#
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "requests",
#   "boto3"
# ]
# ///


import boto3

boto3.DEFAULT_SESSION

print("WOO HOO!")
