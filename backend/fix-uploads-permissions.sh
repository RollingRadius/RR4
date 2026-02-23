#!/bin/bash
# Fix uploads directory permissions for vehicle photo uploads

mkdir -p /home/RR4/backend/uploads/vehicles
mkdir -p /home/RR4/backend/uploads/logos
chmod -R 777 /home/RR4/backend/uploads

echo "✅ Uploads directory permissions fixed."
