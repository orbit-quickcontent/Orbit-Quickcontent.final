import axios from 'axios';
import { logger } from '../lib/logger';
import prisma from '../lib/prisma';

const OSRM_BASE = process.env.OSRM_BASE_URL || 'https://router.project-osrm.org';

export interface RouteResult {
  distanceMeters: number;
  durationSeconds: number;
  geometry: any; // GeoJSON LineString
  distanceKm: number;
  durationMinutes: number;
}

// ── Get Route via OSRM ────────────────────────────────────────────────────────
export async function getRoute(
  originLat: number,
  originLng: number,
  destLat: number,
  destLng: number
): Promise<RouteResult | null> {
  try {
    const url = `${OSRM_BASE}/route/v1/driving/${originLng},${originLat};${destLng},${destLat}`;
    const response = await axios.get(url, {
      params: {
        overview: 'full',
        geometries: 'geojson',
        steps: false,
      },
      timeout: 8000,
    });

    if (response.data.code !== 'Ok' || !response.data.routes?.length) {
      logger.warn({ originLat, originLng, destLat, destLng }, 'OSRM returned no routes');
      return null;
    }

    const route = response.data.routes[0];
    return {
      distanceMeters: route.distance,
      durationSeconds: route.duration,
      geometry: route.geometry,
      distanceKm: Math.round(route.distance / 100) / 10,
      durationMinutes: Math.ceil(route.duration / 60),
    };
  } catch (err: any) {
    logger.error({ err: err.message }, 'OSRM route request failed');
    return null;
  }
}

// ── Geocode address (fallback to coordinates) ──────────────────────────────────
export async function reverseGeocode(lat: number, lng: number): Promise<string> {
  try {
    const response = await axios.get('https://nominatim.openstreetmap.org/reverse', {
      params: { lat, lon: lng, format: 'json' },
      headers: { 'User-Agent': 'ORBIT-Platform/1.0' },
      timeout: 5000,
    });
    return response.data.display_name || `${lat.toFixed(4)}, ${lng.toFixed(4)}`;
  } catch {
    return `${lat.toFixed(4)}, ${lng.toFixed(4)}`;
  }
}
