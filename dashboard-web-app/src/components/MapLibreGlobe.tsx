"use client";

import React, { useEffect, useRef } from "react";
import maplibregl from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";

export default function MapLibreGlobe() {
  const mapContainer = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!mapContainer.current) return;

    const map = new maplibregl.Map({
      container: mapContainer.current,
      style: "https://demotiles.maplibre.org/globe.json", // style URL
      center: [0, 0], // starting position [lng, lat]
      zoom: 1, // starting zoom
    });

    // Cleanup map on unmount
    return () => {
      map.remove();
    };
  }, []);

  return (
    <div className="w-full h-full relative min-h-[400px]">
      <div ref={mapContainer} className="absolute inset-0 w-full h-full rounded-md" />
    </div>
  );
}
