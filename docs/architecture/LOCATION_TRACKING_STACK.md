# ORBIT FINAL MAP + LOCATION + LIVE TRACKING STACK

## 1. MAP
**MapLibre**
https://maplibre.org/

## 2. MAP DATA / TILES
**OpenStreetMap**
https://www.openstreetmap.org/

## 3. GEOCODING
**Nominatim**
https://nominatim.openstreetmap.org/

## 4. ROUTING / DISTANCE / ETA
**OSRM (Open Source Routing Machine)**
https://router.project-osrm.org/

## 5. NEARBY PARTNER SEARCH
**Supabase PostgreSQL + PostGIS**
https://supabase.com/

## 6. REAL-TIME LIVE LOCATION
**Socket.IO**
https://socket.io/

## 7. GPS / LOCATION FROM MOBILE
**Flutter Geolocator**
https://pub.dev/packages/geolocator

## 8. BACKEND API
**Node.js + Express**
https://nodejs.org/
https://expressjs.com/

---

## FINAL ORBIT STACK:
MapLibre + OpenStreetMap + Nominatim + OSRM + Supabase PostgreSQL/PostGIS + Socket.IO + Flutter Geolocator + Node.js/Express

---

## ORBIT FLOW:
1. **Client GPS**
    ↓
2. **Node.js + Express**
    ↓
3. **Supabase/PostGIS**
    ↓
4. **Find nearby partners**
    ↓
5. **Socket.IO**
    ↓
6. **Partner receives request**
    ↓
7. **Partner accepts**
    ↓
8. **OSRM**
    ↓
9. **Route + Distance + ETA**
    ↓
10. **MapLibre + OpenStreetMap**
    ↓
11. **Client sees partner**
    ↓
12. **Socket.IO**
    ↓
13. **LIVE PARTNER LOCATION**
