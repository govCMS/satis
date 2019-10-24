# The image pushed to Quay.io after tests are run.
# This image is referenced by Lagoon.

FROM amazeeio/nginx:latest

COPY app/ /app/
