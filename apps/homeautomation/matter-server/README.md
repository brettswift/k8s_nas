# Matter Server (Home Assistant)

Runs [python-matter-server](https://github.com/home-assistant-libs/python-matter-server) so Home Assistant in Kubernetes can use the **Matter** integration and discover **Thread** devices (e.g. on an Aqara M100 or other Thread border router).

## Why this is needed

- Home Assistant OS can use the built-in Matter add-on; in k8s there is no add-on, so we run the Matter server as a separate deployment.
- Zigbee devices are discovered by HA via the Zigbee coordinator; Thread devices require Matter support. This container provides the Matter controller that HA talks to.

## How Home Assistant connects

1. Ensure this app is deployed and synced in ArgoCD (namespace `homeautomation`).
2. In Home Assistant: **Settings → Devices & services → Add integration**.
3. Search for **Matter** and add it.
4. Choose **Use an existing Matter server** and enter:

   **URL:** `http://matter-server.homeautomation.svc.cluster.local:5580`

   (HA runs in the same cluster and namespace, so this internal URL works.)

5. Complete the flow; the Matter integration will then use this server for commissioning and controlling Matter/Thread devices.

## Thread and Aqara M100

- Your **Aqara M100** (or other hub) acts as the **Thread border router**. This deployment does not run an OTBR; it only runs the Matter server.
- For Thread devices on the M100 to be used by HA via Matter, you may need to:
  - Add the **Thread** integration in HA and, if prompted, set your border router’s network as preferred, or
  - In the Matter integration, add devices by commissioning them (pairing codes / QR); Thread credentials may be shared when the M100 and Matter server are on the same LAN and the network is preferred.

If you see “No preferred network found” when linking the M100, check the [Home Assistant Matter/Thread community forums](https://community.home-assistant.io/c/configuration/matter-thread/93); some hub firmware versions need specific steps.

## Deployment details

- **Image:** `ghcr.io/home-assistant-libs/python-matter-server:stable`
- **Port:** 5580 (WebSocket API for HA).
- **hostNetwork: true** so the server can participate in mDNS/ discovery on the node network; required for Matter device discovery.
- **Storage:** PVC `matter-server-storage` (1Gi) for persistent Matter data (commissioned devices, etc.); do not delete if you want to keep devices.

## Optional: open the server from your machine

From a machine that can reach the cluster (e.g. same LAN as the k3s node), the server is also reachable on the **node IP** and port **5580** (because the pod uses host networking). You can use that for debugging; the main use is via HA’s Matter integration with the URL above.
