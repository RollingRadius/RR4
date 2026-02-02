# OSRM (Open Source Routing Machine) Setup Guide

This guide explains how to set up the OSRM routing engine for route optimization in the GPS tracking system.

## Prerequisites

- Docker and Docker Compose installed
- At least 4GB of free disk space for map data
- Internet connection to download map data

## Quick Start

### 1. Create OSRM Data Directory

```bash
cd backend
mkdir -p osrm-data
```

### 2. Download Map Data

Download OpenStreetMap data for India (or your region):

```bash
# For India (approximately 1GB download, 2-3GB processed)
wget https://download.geofabrik.de/asia/india-latest.osm.pbf -O osrm-data/india-latest.osm.pbf

# Alternative: For smaller region (e.g., Delhi)
# wget https://download.geofabrik.de/asia/india/delhi-latest.osm.pbf -O osrm-data/delhi-latest.osm.pbf
```

**Available regions:**
- Full India: `https://download.geofabrik.de/asia/india-latest.osm.pbf`
- North India: `https://download.geofabrik.de/asia/india/north-latest.osm.pbf`
- Delhi: `https://download.geofabrik.de/asia/india/delhi-latest.osm.pbf`
- Karnataka: `https://download.geofabrik.de/asia/india/karnataka-latest.osm.pbf`
- More regions: https://download.geofabrik.de/asia/india.html

### 3. Process Map Data

Process the downloaded OSM data for routing (one-time operation):

```bash
# Extract road network
docker run -t -v "$(pwd)/osrm-data:/data" osrm/osrm-backend osrm-extract -p /opt/car.lua /data/india-latest.osm.pbf

# Partition the graph
docker run -t -v "$(pwd)/osrm-data:/data" osrm/osrm-backend osrm-partition /data/india-latest.osrm

# Customize for routing
docker run -t -v "$(pwd)/osrm-data:/data" osrm/osrm-backend osrm-customize /data/india-latest.osrm
```

**Note:** Processing time depends on region size:
- Delhi: ~2-3 minutes
- Full India: ~30-60 minutes

### 4. Start OSRM Server

```bash
# Start OSRM and Redis services
docker-compose up -d

# Check if services are running
docker-compose ps

# View logs
docker-compose logs -f osrm
```

The OSRM service will be available at: `http://localhost:5000`

## Testing OSRM

Test the OSRM server is working:

```bash
# Test route between two points (Delhi coordinates)
curl "http://localhost:5000/route/v1/driving/77.2090,28.6139;77.3910,28.5355?overview=false"

# Test trip optimization (multiple waypoints)
curl "http://localhost:5000/trip/v1/driving/77.2090,28.6139;77.3910,28.5355;77.0266,28.4595?source=first&roundtrip=false"
```

Expected response: JSON with routes and distances.

## Configuration in Backend

Update `backend/app/core/config.py` to add OSRM configuration:

```python
class Settings(BaseSettings):
    # ... existing settings ...

    # OSRM Configuration
    OSRM_BASE_URL: str = "http://localhost:5000"

    # Redis Configuration
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_DB: int = 0
```

## Updating Map Data

To update to latest map data:

```bash
# Stop OSRM service
docker-compose stop osrm

# Download latest map
wget https://download.geofabrik.de/asia/india-latest.osm.pbf -O osrm-data/india-latest.osm.pbf

# Re-process (repeat step 3)
docker run -t -v "$(pwd)/osrm-data:/data" osrm/osrm-backend osrm-extract -p /opt/car.lua /data/india-latest.osm.pbf
docker run -t -v "$(pwd)/osrm-data:/data" osrm/osrm-backend osrm-partition /data/india-latest.osrm
docker run -t -v "$(pwd)/osrm-data:/data" osrm/osrm-backend osrm-customize /data/india-latest.osrm

# Restart OSRM
docker-compose up -d osrm
```

## Troubleshooting

### OSRM container exits immediately

Check logs:
```bash
docker-compose logs osrm
```

Common issues:
- Map data not processed correctly (re-run processing steps)
- Insufficient disk space
- File permissions issue (ensure osrm-data directory is writable)

### "Connection refused" errors

Ensure OSRM is running:
```bash
docker-compose ps
curl http://localhost:5000/route/v1/driving/77.2090,28.6139;77.3910,28.5355
```

### Slow routing performance

- Use a smaller region (e.g., state instead of full country)
- Increase Docker memory allocation (4GB+ recommended)
- Consider using a production server with more RAM

## Production Deployment

For production:

1. **Use external hosting**: Deploy OSRM on a dedicated server with sufficient resources
2. **Update base URL**: Set `OSRM_BASE_URL` to production server URL
3. **Add authentication**: Place OSRM behind API gateway with authentication
4. **Regular updates**: Schedule map data updates monthly
5. **Monitoring**: Monitor OSRM container health and response times

### Recommended Specifications

- **Small region** (single state): 2GB RAM, 10GB disk
- **Large region** (full country): 8GB RAM, 50GB disk
- **CPU**: 2+ cores for better concurrent request handling

## API Endpoints Used

The tracking service uses these OSRM endpoints:

- **Trip optimization**: `/trip/v1/driving/{coordinates}?source=first&roundtrip=false`
  - Optimizes waypoint order for shortest route
  - Used by route optimizer feature

- **Route calculation**: `/route/v1/driving/{coordinates}`
  - Calculates shortest path between points
  - Returns distance and duration

## Alternative: Cloud OSRM

If self-hosting is not feasible, consider:

- **Mapbox Directions API**: https://docs.mapbox.com/api/navigation/directions/
- **GraphHopper**: https://www.graphhopper.com/
- **OpenRouteService**: https://openrouteservice.org/

Update the `tracking_service.py` to use the alternative API.

## Resources

- OSRM Documentation: http://project-osrm.org/
- OSM Data Extracts: https://download.geofabrik.de/
- Docker Hub: https://hub.docker.com/r/osrm/osrm-backend/
