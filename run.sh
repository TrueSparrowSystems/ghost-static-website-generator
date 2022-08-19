#!/usr/bin/env bash

# Following ENV variables are required.
#   - GHOST_STATIC_CONTENT_DIR (set in Dockerfile)
#   - GHOST_HOSTED_URL (something like "https://content.yoursite.com/blog")
#   - GHOST_STATIC_HOST_URL (something like "https://yoursite.com/blog")
# Optional ENV variables:
#   - CUSTOM_REPLACE_KEYS (comma separated list of items that needs to be replaced from the items in CUSTOM_REPLACE_VALUES at the same index)
#   - CUSTOM_REPLACE_VALUES (associated values for the item in CUSTOM_REPLACE_KEYS)
#   - ROOT_INDEX_JSONLD (LD+JSON data that needs to be replaced in root index.html page)
#   - S3_BUCKET_NAME (S3 bucket name to upload static HTML files)
#   - AWS_ACCESS_KEY_ID
#   - AWS_SECRET_ACCESS_KEY
#   - AWS_DEFAULT_REGION