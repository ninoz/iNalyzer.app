#!/bin/bash
find /opt/classdumper/Payload -type f -exec /opt/classdumper/class-dump -H -o /opt/classdumper/Headers/	"{}" \;
