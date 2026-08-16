import axios from 'axios';
import { logger } from '../lib/logger';

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

// ── Forward Geocode (Address → Coordinates) ──────────────────────────────────
export async function forwardGeocode(query: string): Promise<{ lat: number; lng: number; displayName: string } | null> {
  try {
    const geocodingBase = process.env.GEOCODING_BASE_URL || 'https://nominatim.openstreetmap.org';
    const response = await axios.get(`${geocodingBase}/search`, {
      params: { q: query, format: 'json', limit: 1 },
      headers: { 'User-Agent': 'ORBIT-Platform/1.0' },
      timeout: 5000,
    });
    if (response.data && response.data.length > 0) {
      const item = response.data[0];
      return {
        lat: parseFloat(item.lat),
        lng: parseFloat(item.lon),
        displayName: item.display_name,
      };
    }
    return null;
  } catch (err: any) {
    logger.error({ err: err.message, query }, 'Nominatim forward geocoding failed');
    return null;
  }
}

// ── Geocode address (Coordinates → Address) ──────────────────────────────────
export async function reverseGeocode(lat: number, lng: number): Promise<string> {
  try {
    const geocodingBase = process.env.GEOCODING_BASE_URL || 'https://nominatim.openstreetmap.org';
    const response = await axios.get(`${geocodingBase}/reverse`, {
      params: { lat, lon: lng, format: 'json' },
      headers: { 'User-Agent': 'ORBIT-Platform/1.0' },
      timeout: 5000,
    });
    return response.data.display_name || `${lat.toFixed(4)}, ${lng.toFixed(4)}`;
  } catch {
    return `${lat.toFixed(4)}, ${lng.toFixed(4)}`;
  }
}

