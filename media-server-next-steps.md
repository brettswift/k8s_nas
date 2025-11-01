# Media Server Next Steps

## Current Status ✅

All Starr services are now successfully deployed and running in the `media` namespace:

### Running Services:
- **Sonarr** (Series management) - ✅ Running
- **Radarr** (Movies management) - ✅ Running  
- **Lidarr** (Music management) - ✅ Running
- **Bazarr** (Subtitles management) - ✅ Running
- **Prowlarr** (Indexers management) - ✅ Running
- **Jellyseerr** (Content requests) - ✅ Running
- **Flaresolverr** (CAPTCHA solving) - ✅ Running
- **Sabnzbd** (Usenet client) - ✅ Running (starting up)
- **Unpackerr** (Archive extraction) - ✅ Running
- **Jellyfin** (Media server) - ✅ Running

### Infrastructure:
- **qBittorrent** (with VPN) - ✅ Running in `qbittorrent` namespace
- **ArgoCD** - ✅ Managing all deployments via GitOps

## Next Steps Required

### 1. API Key Configuration 🔑
The Starr services are running but need API keys configured for inter-service communication:

**Required API Keys:**
- **Sonarr**: `aa91f40651d84c2bb03faadc07d9ccbc` (from docker-compose config)
- **Radarr**: `20c22574260f40d691b1256889ba0216` (from docker-compose config)
- **Lidarr**: Need to extract from existing config
- **Bazarr**: Need to extract from existing config
- **Prowlarr**: Need to extract from existing config
- **Jellyseerr**: Need to extract from existing config

**Action Required:**
1. Access each service UI via `https://home.brettswift.com/<service>`
2. Extract API keys from existing configurations
3. Update service configurations to use correct API keys
4. Configure inter-service communication

### 2. Service Integration 🔗
Configure services to communicate with each other:

**Sonarr Configuration:**
- Set download client: qBittorrent (VPN-enabled)
- Set indexers: Prowlarr
- Set root folders: `/data/media/tv`

**Radarr Configuration:**
- Set download client: qBittorrent (VPN-enabled)
- Set indexers: Prowlarr
- Set root folders: `/data/media/movies`

**Prowlarr Configuration:**
- Add Sonarr and Radarr as applications
- Configure indexers for torrent/usenet

**Jellyseerr Configuration:**
- Connect to Jellyfin
- Connect to Sonarr and Radarr
- Configure request management

### 3. Volume Mount Verification 📁
Verify that all services have access to the correct directories:

**Current Mounts:**
- **Config**: `/mnt/data/configs/<service>` (migrated from docker-compose)
- **Media**: `/mnt/data/media` (shared media library)
- **Downloads**: `/mnt/data/downloads` (download directory)

**Action Required:**
1. Verify each service can access its config directory
2. Verify media library access
3. Verify download directory access

### 4. VPN Integration 🌐
Ensure qBittorrent is properly integrated with Starr services:

**Current Status:**
- qBittorrent running with VPN in `qbittorrent` namespace
- VPN IP: `216.131.74.84` (confirmed working)

**Action Required:**
1. Configure Sonarr/Radarr to use qBittorrent as download client
2. Test torrent downloads through VPN
3. Verify all traffic goes through VPN

### 5. SSL Certificate Management 🔒
Ensure all services have proper SSL certificates:

**Current Status:**
- All services accessible via `https://home.brettswift.com/<service>`
- Certificates managed by cert-manager

**Action Required:**
1. Verify SSL certificates are valid
2. Test HTTPS access to all services
3. Configure any missing certificates

### 6. Monitoring and Logging 📊
Set up monitoring for the media services:

**Action Required:**
1. Configure Prometheus monitoring for Starr services
2. Set up Grafana dashboards
3. Configure log aggregation
4. Set up alerts for service failures

### 7. Backup Strategy 💾
Implement backup strategy for configurations and data:

**Action Required:**
1. Backup Starr service configurations
2. Backup media library metadata
3. Set up automated backups
4. Test restore procedures

## Configuration Files Location

**Migrated Configurations:**
- **Location**: `/mnt/data/configs/<service>/`
- **Services**: sonarr, radarr, lidarr, bazarr, prowlarr, jellyseerr, sabnzbd
- **Status**: ✅ Successfully migrated from docker-compose setup

**API Keys Location:**
- **Sonarr**: `/mnt/data/configs/sonarr/config.xml`
- **Radarr**: `/mnt/data/configs/radarr/config.xml`
- **Other services**: Check respective config directories

## Service URLs

All services are accessible via:
- **Sonarr**: https://home.brettswift.com/sonarr
- **Radarr**: https://home.brettswift.com/radarr
- **Lidarr**: https://home.brettswift.com/lidarr
- **Bazarr**: https://home.brettswift.com/bazarr
- **Prowlarr**: https://home.brettswift.com/prowlarr
- **Jellyseerr**: https://home.brettswift.com/jellyseerr
- **Sabnzbd**: https://home.brettswift.com/sabnzbd
- **Jellyfin**: https://home.brettswift.com/jellyfin
- **qBittorrent**: https://home.brettswift.com/qbittorrent

## GitOps Status

**Current Branch**: `dev_starr`
**ApplicationSet**: `media-services-starr`
**Namespace**: `media`
**Status**: ✅ All services deployed and running

## Priority Order

1. **High Priority**: API key configuration and service integration
2. **Medium Priority**: VPN integration testing
3. **Low Priority**: Monitoring, backup, and optimization

---

**Last Updated**: October 28, 2025
**Status**: All Starr services deployed and running successfully
**Next Action**: Configure API keys and service integration


