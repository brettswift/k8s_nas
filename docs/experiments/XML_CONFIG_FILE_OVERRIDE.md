# XML Config File Override System

## Overview

The Jellyfin deployment uses a dynamic XML configuration override system that allows customizing Jellyfin's configuration files without rebuilding the container image.

## How It Works

### 1. Base XML Files
- **`network.xml`** - Base template with default network settings
- Located in `apps/media-services/jellyfin/network.xml`
- Contains default values for BaseUrl, ports, discovery, etc.

### 2. ConfigMap Overrides
- **`configmap.yaml`** - Contains override values in key-value format
- Keys follow pattern: `"filename.xml_xpath=value"`
- Example: `"network.xml_NetworkConfiguration_BaseUrl": "/jellyfin"`

### 3. Init Container Processing
- **Init container** runs `xmlstarlet` to merge overrides into XML files
- Reads each ConfigMap key as a file from `/overrides/` directory
- Parses key name to extract filename and XPath
- Updates the corresponding XML file with the new value

### 4. Volume Mounts
- **`xml-overrides`** volume mounts ConfigMap keys as individual files
- **`network-seed`** volume provides base XML templates
- **`config`** volume stores the final processed XML files

## Current Implementation

### ConfigMap Structure
```yaml
data:
  # Environment variables
  JELLYFIN_PublishedServerUrl: "https://home.brettswift.com/jellyfin"
  
  # XML overrides (file_xpath=value format)
  "network.xml_NetworkConfiguration_BaseUrl": "/jellyfin"
  "network.xml_NetworkConfiguration_EnableHttps": "false"
  "network.xml_NetworkConfiguration_RequireHttps": "false"
  "network.xml_NetworkConfiguration_AutoDiscovery": "true"
  "network.xml_NetworkConfiguration_EnableUPnP": "false"
  "network.xml_NetworkConfiguration_EnableIPv4": "true"
  "network.xml_NetworkConfiguration_EnableIPv6": "false"
  "network.xml_NetworkConfiguration_EnableRemoteAccess": "true"
  "network.xml_NetworkConfiguration_IgnoreVirtualInterfaces": "true"
  "network.xml_NetworkConfiguration_EnablePublishedServerUriByRequest": "false"
  "network.xml_NetworkConfiguration_IsRemoteIPFilterBlacklist": "false"
  "network.xml_NetworkConfiguration_PublishedServerUrl": "https://home.brettswift.com/jellyfin"
```

### Volume Mount (Current)
```yaml
- name: xml-overrides
  configMap:
    name: jellyfin-config
    items:
    - key: "network.xml_NetworkConfiguration_BaseUrl"
      path: "network.xml_NetworkConfiguration_BaseUrl"
    - key: "network.xml_NetworkConfiguration_EnableHttps"
      path: "network.xml_NetworkConfiguration_EnableHttps"
    # ... manual list of each key
```

### Init Container Logic
```bash
# Copy base configs if they don't exist
if [ ! -f /config/network.xml ]; then
  cp /seed/network.xml /config/network.xml
fi

# Apply overrides from ConfigMap
for override in /overrides/*; do
  if [ -f "$override" ]; then
    key=$(basename "$override")
    value=$(cat "$override")
    
    # Parse "file_xpath=value" format
    file=$(echo "$key" | sed 's/_.*$//')
    xpath=$(echo "$key" | sed 's/^[^_]*_//' | sed 's/_/\//g')
    xpath="/$xpath"
    
    # Update XML file
    xmlstarlet ed --inplace -u "$xpath" -v "$value" /config/"$file"
  fi
done
```

## Proposed Improvement

### Problem
- Adding new XML configuration options requires updating the deployment.yaml
- Manual `items:` list in volume mount needs to be maintained
- Not scalable for multiple XML files

### Solution
Mount entire ConfigMap and process all keys automatically:

```yaml
- name: xml-overrides
  configMap:
    name: jellyfin-config
    # Remove 'items' section - mounts ALL keys as files
```

### Benefits
- ✅ No deployment changes needed for new XPaths
- ✅ Supports multiple XML files automatically
- ✅ Truly dynamic configuration system
- ✅ Same parsing logic, just processes all files

## Usage Examples

### Adding New Network Settings
```yaml
# Just add to ConfigMap - no deployment changes needed
"network.xml_NetworkConfiguration_EnableIPv6": "true"
"network.xml_NetworkConfiguration_LocalNetworkSubnets": "192.168.1.0/24"
```

### Adding New XML Files
```yaml
# Future: playback.xml, display.xml, etc.
"playback.xml_PlaybackConfiguration_EnableHardwareAcceleration": "true"
"display.xml_DisplayConfiguration_Theme": "dark"
```

## Testing

To test the improved system:
1. Add a new XPath to ConfigMap
2. Update deployment to mount entire ConfigMap
3. Verify the new setting gets applied to XML
4. Confirm Jellyfin starts with the new configuration

## Files Involved

- `apps/media-services/jellyfin/configmap.yaml` - Override values
- `apps/media-services/jellyfin/network.xml` - Base XML template
- `apps/media-services/jellyfin/deployment.yaml` - Init container logic
- `apps/media-services/jellyfin/kustomization.yaml` - ConfigMap generation
